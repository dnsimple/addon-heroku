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
  Connect the DNSimple domain to the Heroku application using the configuration details
  found in `model`.
  """
  def connect(model) do
    model = Repo.preload(model, :account)
    domain = HerokuConnector.Dnsimple.domain(model.account, model.dnsimple_domain_id)
    app = HerokuConnector.Heroku.app(model.account, model.heroku_app_id)

    dnsimple_connect_results = connect_dnsimple(model.account, domain.name, URI.parse(app.web_url).host)
    heroku_connect_results = connect_heroku(model.account, domain.name, app.id)

    # Function returning true if the result tuple first element is :ok
    success_fn = fn(res) ->
      case res do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end

    # Function to use in filters for removing nil values
    non_nil_fn = &(&1 != nil)

    # Function to extract the ID from the result tuple {:ok, id}
    extract_id_fn = fn({:ok, id}) -> id end

    # Currently there is a behaivor in the DNSimple API where record creation fails but the
    # endpoint returns a 201 with nil ids in the records that are returned. The second filter
    # in the chain below filters out those nil ids.
    connection_data = %ConnectionData{
      dnsimple_record_ids: Enum.filter_map(dnsimple_connect_results, success_fn, extract_id_fn) |> Enum.filter(non_nil_fn),
      heroku_domain_ids: Enum.filter_map(heroku_connect_results, success_fn, extract_id_fn)
    }

    changeset = model
    |> change
    |> put_embed(:connection_data, connection_data)

    update(changeset)

    case Enum.all?(dnsimple_connect_results ++ heroku_connect_results, success_fn) do
      true ->
        {:ok, model}
      false ->
        get!(model.account, model.id) |> disconnect! |> delete!
        {:error, dnsimple_connect_results ++ heroku_connect_results}
    end
  end

  defp dnsimple_records(app_hostname) do
    [
      %Dnsimple.Record{type: "ALIAS", name: "", content: app_hostname, ttl: 3600},
      %Dnsimple.Record{type: "CNAME", name: "www", content: app_hostname, ttl: 3600}
    ]
  end

  defp connect_dnsimple(account, domain_name, app_hostname) do
    HerokuConnector.Dnsimple.create_records(account, domain_name, dnsimple_records(app_hostname))
    |> Enum.map(fn(result) ->
      case result do
        {:ok, response} -> {:ok, response.data.id}
        {:error, error} -> {:error, error}
      end
    end)
  end

  defp connect_dnsimple!(account, domain_name, app_hostname) do
    HerokuConnector.Dnsimple.create_records(account, domain_name, dnsimple_records(app_hostname))
    |> Enum.map(fn(result) ->
      case result do
        {:ok, response} -> response.data.id
        {:error, error} -> raise "Error adding record: #{inspect error}"
      end
    end)
  end

  defp heroku_hostnames(domain_name) do
     [domain_name, "www.#{domain_name}"]
  end

  defp connect_heroku(account, domain_name, app_id) do
    HerokuConnector.Heroku.create_domains(account, app_id, heroku_hostnames(domain_name))
    |> Enum.map(fn(res) ->
      case res do
        %Happi.Heroku.Domain{id: id} -> {:ok, id}
        _ -> {:error, res}
      end
    end)
  end

  defp connect_heroku!(account, domain_name, app_id) do
    HerokuConnector.Heroku.create_domains(account, app_id, heroku_hostnames(domain_name))
    |> Enum.map(fn(res) ->
      case res do
        %Happi.Heroku.Domain{id: id} -> id
        _ -> raise "Error adding heroku domain: #{inspect res}"
      end
    end)
  end

  @doc """
  Disconnect the DNSimple domain from the Heroku application using the configuration
  details found in `model`.
  """
  def disconnect!(model) do
    model = Repo.preload(model, :account)
    domain = HerokuConnector.Dnsimple.domain(model.account, model.dnsimple_domain_id)
    app = HerokuConnector.Heroku.app(model.account, model.heroku_app_id)

    disconnect_dnsimple!(model.account, domain.name, model.connection_data.dnsimple_record_ids)
    disconnect_heroku!(model.account, app.id, model.connection_data.heroku_domain_ids)

    model
  end

  defp disconnect_dnsimple!(account, domain_name, dnsimple_record_ids) do
    HerokuConnector.Dnsimple.delete_records(account, domain_name, dnsimple_record_ids)
  end

  defp disconnect_heroku!(account, app_id, heroku_domain_ids) do
    HerokuConnector.Heroku.delete_domains(account, app_id, heroku_domain_ids)
  end
end
