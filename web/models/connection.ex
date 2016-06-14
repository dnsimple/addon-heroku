defmodule HerokuConnector.Connection do

  defmodule Configuration do
    use Ecto.Schema

    embedded_schema do
    end
  end

  defmodule ConnectionData do
    use Ecto.Schema

    embedded_schema do
      field :dnsimple_record_ids, {:array, :integer}, default: []
      field :heroku_domain_ids, {:array, :string}, default: []
    end
  end

  use HerokuConnector.Web, :model
  import Ecto.Query, only: [from: 2]
  require Logger

  alias HerokuConnector.Connection

  schema "connections" do
    belongs_to :account, HerokuConnector.Account
    field :dnsimple_domain_id, :string
    field :heroku_app_id, :string
    embeds_one :configuration, HerokuConnector.Connection.Configuration, on_replace: :delete
    embeds_one :connection_data, HerokuConnector.Connection.ConnectionData, on_replace: :delete

    timestamps
  end

  @required_fields ~w(account_id dnsimple_domain_id heroku_app_id)
  @optional_fields ~w()

  def create(model, params \\ %{}) do
    model
    |> changeset(params)
    |> Repo.insert
  end

  def create!(model, params \\ %{}) do
    model
    |> changeset(params)
    |> Repo.insert!
  end

  def get(account, id) do
    query = from c in Connection, where: c.account_id == ^account.id
    Repo.get(query, id)
  end

  def get!(account, id) do
    query = from c in Connection, where: c.account_id == ^account.id
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

  @doc """
  Execute the connection at DNSimple and Heroku.
  """
  def connect!(model) do
    model = Repo.preload(model, :account)

    domain = HerokuConnector.Dnsimple.domain(model.account, model.dnsimple_domain_id)
    app = HerokuConnector.Heroku.app(model.account, model.heroku_app_id)
    uri = URI.parse(app.web_url)

    # DNSimple record setup
    dnsimple_records = [
      %Dnsimple.Record{type: "ALIAS", name: "", content: uri.host, ttl: 3600},
      %Dnsimple.Record{type: "CNAME", name: "www", content: uri.host, ttl: 3600}
    ]

    dnsimple_record_ids = HerokuConnector.Dnsimple.create_records(model.account, domain.name, dnsimple_records)
    |> Enum.map(fn(result) ->
      case result do
        {:ok, response} -> response.data.id
        {:error, error} -> raise "Error adding record: #{inspect error}"
      end
    end)

    # Heroku domain setup
    heroku_hostnames = [
      domain.name,
      "www.#{domain.name}"
    ]

    heroku_domain_ids = HerokuConnector.Heroku.create_domains(model.account, app.id, heroku_hostnames)
    |> Enum.map(fn(res) ->
      case res do
        %Happi.Heroku.Domain{id: id} -> id
        _ -> raise "Error adding heroku domain: #{inspect res}"
      end
    end)

    # Persist everything
    connection_data = %ConnectionData{dnsimple_record_ids: dnsimple_record_ids, heroku_domain_ids: heroku_domain_ids}

    changeset = model
    |> change
    |> put_embed(:connection_data, connection_data)

    update(changeset)

    model
  end

  def disconnect!(model) do
    model = Repo.preload(model, :account)

    domain = HerokuConnector.Dnsimple.domain(model.account, model.dnsimple_domain_id)
    HerokuConnector.Dnsimple.delete_records(model.account, domain.name, model.connection_data.dnsimple_record_ids)

    app = HerokuConnector.Heroku.app(model.account, model.heroku_app_id)
    HerokuConnector.Heroku.delete_domains(model.account, app.id, model.connection_data.heroku_domain_ids)

    model
  end
end
