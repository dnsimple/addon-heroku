defmodule HerokuConnector.Connection do

  defmodule Configuration do
    use Ecto.Schema

    embedded_schema do
    end
  end

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

  @doc """
  Connect the DNSimple domain to the Heroku application using the configuration details
  found in `model`.
  """
  def connect(model, connection_params \\ %{}) do
    model = Repo.preload(model, :account)

    domain = HerokuConnector.Dnsimple.domain(model.account, model.dnsimple_domain_id)
    app = HerokuConnector.Heroku.app(model.account, model.heroku_app_id)

    case Map.get(connection_params, "dnsimple_certificate_id") do
      # No certificate is present
      nil ->
        dnsimple_connect_results = connect_dnsimple(model.account, domain.name, URI.parse(app.web_url).host)
        heroku_connect_results = connect_heroku(model.account, domain.name, app.id)
        save_connection_data(model, dnsimple_connect_results, heroku_connect_results)

        case Enum.all?(dnsimple_connect_results ++ heroku_connect_results, success_fn) do
          true ->
            {:ok, model}
          false ->
            get!(model.account, model.id) |> disconnect! |> delete!
            {:error, dnsimple_connect_results ++ heroku_connect_results}
        end

      # Certificate present
      dnsimple_certificate_id ->
        case enable_heroku_ssl_endpoint(model.account, model.dnsimple_domain_id, app.id, dnsimple_certificate_id) do
          {:ok, ssl_endpoint} ->
            dnsimple_connect_results = connect_dnsimple(model.account, domain.name, ssl_endpoint.cname)
            heroku_connect_results = connect_heroku(model.account, domain.name, app.id)
            save_connection_data(model, dnsimple_connect_results, heroku_connect_results, ssl_endpoint.id)

            case Enum.all?(dnsimple_connect_results ++ heroku_connect_results, success_fn) do
              true ->
                {:ok, model}
              false ->
                get!(model.account, model.id) |> disconnect! |> delete!
                {:error, dnsimple_connect_results ++ heroku_connect_results}
            end
          {:error, error} ->
            IO.inspect("Error enabling SSL endpoint: #{inspect error}")
            {:error, error}
        end
    end
  end

  defp save_connection_data(model, dnsimple_connect_results, heroku_connect_results, ssl_endpoint_id \\ nil) do
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

  defp enable_heroku_ssl_endpoint(account, domain_name, app_id, dnsimple_certificate_id) do
    # Currently this implementation relies on the SSL add-on.
    # Eventually replace it with Heroku SSL (https://devcenter.heroku.com/articles/ssl-beta)

    # Enable the SSL add-on
    addon = HerokuConnector.Heroku.create_addon(account, app_id, _addon_id = "ssl:endpoint")
    IO.inspect addon

    # Create the SSL endpoint
    downloaded_certificate = HerokuConnector.Dnsimple.download_certificate(account, domain_name, dnsimple_certificate_id)
    certificate_bundle = List.flatten([downloaded_certificate.server, downloaded_certificate.chain]) |> Enum.join("\n")
    IO.inspect certificate_bundle
    private_key = HerokuConnector.Dnsimple.private_key(account, domain_name, dnsimple_certificate_id).private_key
    ssl_endpoint = HerokuConnector.Heroku.create_ssl_endpoint(account, app_id, certificate_bundle, private_key)
    IO.inspect ssl_endpoint

    # Return the SSL endpoint
    {:ok, ssl_endpoint}
  end

  defp dnsimple_records(app_hostname) do
    [
      %Dnsimple.ZoneRecord{type: "ALIAS", name: "", content: app_hostname, ttl: 3600},
      %Dnsimple.ZoneRecord{type: "CNAME", name: "www", content: app_hostname, ttl: 3600}
    ]
  end

  defp connect_dnsimple(account, domain_name, app_hostname) do
    # Unapply existing Heroku one-click service if necessary
    unapplied_services = case HerokuConnector.Dnsimple.applied_services(account, domain_name) do
      [] -> []
      services ->
        services
        |> Enum.filter(&(&1.short_name =~ ~r/heroku/))
        |> Enum.map(&(HerokuConnector.Dnsimple.unapply_service(account, domain_name, &1.id)))
    end

    # Create the appropriate DNSimple records
    HerokuConnector.Dnsimple.create_records(account, domain_name, dnsimple_records(app_hostname))
    |> Enum.map(fn(result) ->
      case result do
        {:ok, response} -> {:ok, response.data.id}
        {:error, error} ->
          # Failed to create records, re-apply removed services
          Enum.each(unapplied_services, &(HerokuConnector.Dnsimple.apply_service(account, domain_name, &1)))
          {:error, error}
      end
    end)
  end

  defp heroku_hostnames(domain_name) do
     [domain_name, "www.#{domain_name}"]
  end

  defp connect_heroku(account, domain_name, app_id) do
    # Create the appropriate custom domains in Heroku
    HerokuConnector.Heroku.create_domains(account, app_id, heroku_hostnames(domain_name))
    |> Enum.map(fn(res) ->
      case res do
        %Happi.Heroku.Domain{id: id} -> {:ok, id}
        _ -> {:error, res}
      end
    end)
  end

  # The functions in this section handle disconnecting and reconnecting a domain to an Heroku app
  # in cases where either the domain or app is changed.

  @doc """
  Reconnect the connection using the changes in the `changeset`.

  If either the heroku app or the DNSimple domain change, then both must be
  disconnected and connected.
  """
  def reconnect(changeset) do
    model = changeset.data |> Repo.preload(:account)
    domain = HerokuConnector.Dnsimple.domain(model.account, model.dnsimple_domain_id)
    app = HerokuConnector.Heroku.app(model.account, model.heroku_app_id)
    new_domain = case Map.get(changeset.changes, :dnsimple_domain_id) do
      nil -> domain
      dnsimple_domain_id ->  HerokuConnector.Dnsimple.domain(model.account, dnsimple_domain_id)
    end
    new_app = case Map.get(changeset.changes, :heroku_app_id) do
      nil -> app
      heroku_app_id ->  HerokuConnector.Heroku.app(model.account, heroku_app_id)
    end

    case domain.id != new_domain.id or app.id != new_app.id do
      true ->
        dnsimple_connect_results = reconnect_dnsimple(model, domain, app, new_domain, new_app)
        heroku_connect_results = reconnect_heroku(model, domain, app, new_domain, new_app)

        save_connection_data(model, dnsimple_connect_results, heroku_connect_results)
        {:ok, dnsimple_connect_results ++ heroku_connect_results}
      false ->
        {:ok, []}
    end
  end

  defp reconnect_dnsimple(model, domain, _app, new_domain, new_app) do
    disconnect_dnsimple!(model.account, domain.name, model.connection_data.dnsimple_record_ids)
    connect_dnsimple(model.account, new_domain.name, URI.parse(new_app.web_url).host)
  end

  defp reconnect_heroku(model, _domain, app, new_domain, new_app) do
    disconnect_heroku!(model.account, app.id, model.connection_data.heroku_domain_ids)
    connect_heroku(model.account, new_domain.name, new_app.id)
  end


  # The functions in this section handle disconnecting a domain from a Heroku app.

  @doc """
  Disconnect the DNSimple domain from the Heroku application using the configuration
  details found in `model`.
  """
  def disconnect!(model) do
    model = Repo.preload(model, :account)
    domain = HerokuConnector.Dnsimple.domain(model.account, model.dnsimple_domain_id)
    app = HerokuConnector.Heroku.app(model.account, model.heroku_app_id)

    if model.connection_data != nil do
      disconnect_dnsimple!(model.account, domain.name, model.connection_data.dnsimple_record_ids)
      disconnect_heroku!(model.account, app.id, model.connection_data.heroku_domain_ids)

      model |> clear_connection_data!
    else
      model
    end
  end

  defp disconnect_dnsimple!(account, domain_name, dnsimple_record_ids) do
    HerokuConnector.Dnsimple.delete_records(account, domain_name, dnsimple_record_ids)
  end

  defp disconnect_heroku!(account, app_id, heroku_domain_ids) do
    HerokuConnector.Heroku.delete_domains(account, app_id, heroku_domain_ids)
  end

  defp clear_connection_data!(model) do
    cs = model.connection_data |> ConnectionData.changeset(%{dnsimple_record_ids: [], heroku_domain_ids: []})

    # Persist the connection data into the connection
    model
    |> change
    |> put_embed(:connection_data, cs)
    |> update!
  end

  defp success_fn do
    fn(res) ->
      case res do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end
  end

  defp non_nil_fn, do: &(&1 != nil)

  defp extract_id_fn, do: fn({:ok, id}) -> id end
end
