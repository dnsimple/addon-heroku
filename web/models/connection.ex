defmodule HerokuConnector.Connection do

  defmodule ConnectionData do
    use HerokuConnector.Web, :model

    @required_fields ~w(dnsimple_record_ids heroku_domain_ids)
    @optional_fields ~w(ssl_endpoint_id)

    embedded_schema do
      field :dnsimple_record_ids, {:array, :integer}, default: []
      field :heroku_domain_ids, {:array, :string}, default: []
      field :ssl_endpoint_id, :string, default: nil
    end

    def changeset(model, params \\ :invalid) do
      model
      |> cast(params, @required_fields, @optional_fields)
    end
  end

  use HerokuConnector.Web, :model
  import Ecto.Query, only: [from: 2]
  import HerokuConnector.Functions
  require Logger

  alias HerokuConnector.Connection

  schema "connections" do
    belongs_to :account, HerokuConnector.Account
    field :dnsimple_domain_id, :string
    field :heroku_app_id, :string
    field :configuration, :map
    embeds_one :connection_data, HerokuConnector.Connection.ConnectionData, on_replace: :delete

    timestamps
  end

  @required_fields ~w(account_id dnsimple_domain_id heroku_app_id)
  @optional_fields ~w()

  def create(model, params \\ %{}) do
    case model |> changeset(params) |> Repo.insert do
      {:ok, connection} -> {:ok, connection |> Repo.preload([:account])}
      {:error, reason} -> {:error, reason}
    end
  end

  def create!(model, params \\ %{}) do
    model
    |> changeset(params)
    |> Repo.insert!
    |> Repo.preload([:account])
  end

  def get(account, id) do
    query = from c in Connection, where: c.account_id == ^account.id, preload: [:account]
    Repo.get(query, id)
  end

  def get!(account, id) do
    query = from c in Connection, where: c.account_id == ^account.id, preload: [:account]
    Repo.get!(query, id)
  end

  def all(account) do
    query = from c in Connection, where: c.account_id == ^account.id
    Repo.all(query)
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :invalid) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def update(changeset) do
    Repo.update(changeset)
  end

  def update!(changeset) do
    Repo.update!(changeset)
  end

  def delete(model) do
    Repo.delete(model)
  end

  def delete!(model) do
    Repo.delete!(model)
  end

  def save_connection_data(model, dnsimple_connect_results, heroku_connect_results, ssl_endpoint_id \\ nil) do
    # Currently there is a behavior in the DNSimple API where record creation fails but the
    # endpoint returns a 201 with nil ids in the records that are returned. The second filter
    # in the chain below filters out those nil ids.
    connection_data = %ConnectionData{
      dnsimple_record_ids: Enum.filter_map(dnsimple_connect_results, success_fn, extract_id_fn) |> Enum.filter(non_nil_fn),
      heroku_domain_ids: Enum.filter_map(heroku_connect_results, success_fn, extract_id_fn),
      ssl_endpoint_id: ssl_endpoint_id
    }

    # Persist the connection data into the connection
    model
    |> change
    |> put_embed(:connection_data, connection_data)
    |> update
  end

  def clear_connection_data!(model) do
    cs = model.connection_data |> ConnectionData.changeset(%{dnsimple_record_ids: [], heroku_domain_ids: []})

    # Persist the connection data into the connection
    model
    |> change
    |> put_embed(:connection_data, cs)
    |> update!
  end

end
