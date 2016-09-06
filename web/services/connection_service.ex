defmodule HerokuConnector.ConnectionService do
  use HerokuConnector.Web, :model

  import HerokuConnector.Functions

  alias HerokuConnector.Connection

  require Logger

  @doc """
  Connect the DNSimple domain to the Heroku application using the configuration details
  found in `model`.
  """
  def connect(connection, connection_params \\ %{}) do
    domain = HerokuConnector.Dnsimple.domain(connection.account, connection.dnsimple_domain_id)
    app = HerokuConnector.Heroku.app(connection.account, connection.heroku_app_id)

    case Map.get(connection_params, "dnsimple_certificate_id") do
      # No certificate is present
      nil -> connect_without_certificate(connection, domain, app)
      "0" -> connect_without_certificate(connection, domain, app)

      # Certificate present
      dnsimple_certificate_id ->
        connect_with_certificate(connection, domain, app, dnsimple_certificate_id)
    end
  end

  defp connect_without_certificate(connection, domain, app) do
    dnsimple_connect_results = connect_dnsimple(connection.account, domain.name, URI.parse(app.web_url).host)
    heroku_connect_results = connect_heroku(connection.account, domain.name, app.id)
    Connection.save_connection_data(connection, dnsimple_connect_results, heroku_connect_results)

    case Enum.all?(dnsimple_connect_results ++ heroku_connect_results, success_fn) do
      true ->
        {:ok, connection}
      false ->
        Connection.get!(connection.account, connection.id)
        |> disconnect!
        |> Connection.delete!
        {:error, dnsimple_connect_results ++ heroku_connect_results}
    end
  end

  defp connect_with_certificate(connection, domain, app, dnsimple_certificate_id) do
    case enable_heroku_ssl_endpoint(connection.account, connection.dnsimple_domain_id, app.id, dnsimple_certificate_id, nil) do
      {:ok, ssl_endpoint} ->
        dnsimple_connect_results = connect_dnsimple(connection.account, domain.name, ssl_endpoint.cname)
        heroku_connect_results = connect_heroku(connection.account, domain.name, app.id)
        Connection.save_connection_data(connection, dnsimple_connect_results, heroku_connect_results, ssl_endpoint.id)

        case Enum.all?(dnsimple_connect_results ++ heroku_connect_results, success_fn) do
          true ->
            {:ok, connection}
          false ->
            Connection.get!(connection.account, connection.id)
            |> disconnect!
            |> Connection.delete!
            {:error, dnsimple_connect_results ++ heroku_connect_results}
        end
      {:error, error} ->
        IO.inspect("Error enabling SSL endpoint: #{inspect error}")
        {:error, error}
    end
  end

  def enable_heroku_ssl_endpoint(account, domain_name, app_id, dnsimple_certificate_id, ssl_endpoint_id) do
    # Turn on the SSL add-on if necessary
    # Currently this implementation relies on the SSL add-on.
    # Eventually replace it with Heroku SSL (https://devcenter.heroku.com/articles/ssl-beta)
    case HerokuConnector.Heroku.addon_enabled?(account, app_id, "ssl:endpoint") do
      false ->
        HerokuConnector.Heroku.create_addon(account, app_id, _addon_id = "ssl:endpoint")
      _ ->
        :ok # Do nothing
    end

    # Install or update the SSL endpoint
    case ssl_endpoint_id do
      nil -> install_heroku_ssl_endpoint(account, domain_name, app_id, dnsimple_certificate_id)
      _ -> update_heroku_ssl_endpoint(account, domain_name, app_id, dnsimple_certificate_id, ssl_endpoint_id)
    end
  end

  def install_heroku_ssl_endpoint(account, domain_name, app_id, dnsimple_certificate_id) do
    # Create the SSL endpoint
    {private_key, certificate_bundle} = certificate_parts(account, domain_name, dnsimple_certificate_id)
    ssl_endpoint = HerokuConnector.Heroku.create_ssl_endpoint(account, app_id, certificate_bundle, private_key)

    # Return the SSL endpoint
    {:ok, ssl_endpoint}
  end

  def update_heroku_ssl_endpoint(account, domain_name, app_id, dnsimple_certificate_id, ssl_endpoint_id) do
    # Update the SSL endpoint
    {private_key, certificate_bundle} = certificate_parts(account, domain_name, dnsimple_certificate_id)
    ssl_endpoint = HerokuConnector.Heroku.update_ssl_endpoint(account, app_id, certificate_bundle, private_key, ssl_endpoint_id)

    {:ok, ssl_endpoint}
  end

  defp certificate_parts(account, domain_name, dnsimple_certificate_id) do
    downloaded_certificate = HerokuConnector.Dnsimple.download_certificate(account, domain_name, dnsimple_certificate_id)
    certificate_bundle = List.flatten([downloaded_certificate.server, downloaded_certificate.chain]) |> Enum.join("\n")
    private_key = HerokuConnector.Dnsimple.private_key(account, domain_name, dnsimple_certificate_id).private_key
    {private_key, certificate_bundle}
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
  def reconnect(changeset, connection_params \\ %{}) do
    connection = changeset.data |> Repo.preload(:account)
    domain = HerokuConnector.Dnsimple.domain(connection.account, connection.dnsimple_domain_id)
    app = HerokuConnector.Heroku.app(connection.account, connection.heroku_app_id)
    new_domain = case Map.get(changeset.changes, :dnsimple_domain_id) do
      nil -> domain
      dnsimple_domain_id ->  HerokuConnector.Dnsimple.domain(connection.account, dnsimple_domain_id)
    end
    new_app = case Map.get(changeset.changes, :heroku_app_id) do
      nil -> app
      heroku_app_id ->  HerokuConnector.Heroku.app(connection.account, heroku_app_id)
    end

    case domain.id != new_domain.id or app.id != new_app.id do
      true ->
        # something has changed so it's time to reconnect
        if connection.connection_data.ssl_endpoint_id != nil do
          disable_heroku_ssl_endpoint!(connection.account, app.id, connection.connection_data.ssl_endpoint_id)
        end

        case Map.get(connection_params, "dnsimple_certificate_id") do
          nil ->
            # no certificate id is present
            dnsimple_connect_results = reconnect_dnsimple(connection, domain, app, new_domain, new_app, URI.parse(new_app.web_url).host)
            heroku_connect_results = reconnect_heroku(connection, domain, app, new_domain, new_app)
            Connection.save_connection_data(connection, dnsimple_connect_results, heroku_connect_results)
            {:ok, dnsimple_connect_results ++ heroku_connect_results}
          dnsimple_certificate_id ->
            # certificate id is present
            case enable_heroku_ssl_endpoint(connection.account, new_domain.id, new_app.id, dnsimple_certificate_id, connection.ssl_endpoint_id) do
              {:ok, ssl_endpoint} ->
                dnsimple_connect_results = reconnect_dnsimple(connection, domain, app, new_domain, new_app, ssl_endpoint.cname)
                heroku_connect_results = reconnect_heroku(connection, domain, app, new_domain, new_app)
                Connection.save_connection_data(connection, dnsimple_connect_results, heroku_connect_results)
                {:ok, dnsimple_connect_results ++ heroku_connect_results}
              {:error, error} ->
                IO.inspect("Error enabling SSL endpoint: #{inspect error}")
                {:error, error}
            end
        end
      false ->
        {:ok, []}
    end
  end

  defp reconnect_dnsimple(connection, domain, _app, new_domain, _new_app, hostname) do
    disconnect_dnsimple!(connection.account, domain.name, connection.connection_data.dnsimple_record_ids)
    connect_dnsimple(connection.account, new_domain.name, hostname)
  end

  defp reconnect_heroku(connection, _domain, app, new_domain, new_app) do
    disconnect_heroku!(connection.account, app.id, connection.connection_data.heroku_domain_ids)
    connect_heroku(connection.account, new_domain.name, new_app.id)
  end


  # The functions in this section handle disconnecting a domain from a Heroku app.

  @doc """
  Disconnect the DNSimple domain from the Heroku application using the configuration
  details found in `connection`.
  """
  def disconnect!(connection) do
    domain = HerokuConnector.Dnsimple.domain(connection.account, connection.dnsimple_domain_id)
    app = HerokuConnector.Heroku.app(connection.account, connection.heroku_app_id)

    if connection.connection_data != nil do
      if connection.connection_data.ssl_endpoint_id != nil do
        disable_heroku_ssl_endpoint!(connection.account, app.id, connection.connection_data.ssl_endpoint_id)
      end
      disconnect_dnsimple!(connection.account, domain.name, connection.connection_data.dnsimple_record_ids)
      disconnect_heroku!(connection.account, app.id, connection.connection_data.heroku_domain_ids)

      connection |> Connection.clear_connection_data!
    else
      connection
    end
  end

  defp disconnect_dnsimple!(account, domain_name, dnsimple_record_ids) do
    HerokuConnector.Dnsimple.delete_records(account, domain_name, dnsimple_record_ids)
  end

  defp disconnect_heroku!(account, app_id, heroku_domain_ids) do
    HerokuConnector.Heroku.delete_domains(account, app_id, heroku_domain_ids)
  end

  defp disable_heroku_ssl_endpoint!(account, app_id, ssl_endpoint_id) do
    # Currently this implementation relies on the SSL add-on.
    # Eventually replace it with Heroku SSL (https://devcenter.heroku.com/articles/ssl-beta)

    # Remove the SSL endpoint
    HerokuConnector.Heroku.delete_ssl_endpoint(account, app_id, ssl_endpoint_id)

    # Disable the SSL add-on
    HerokuConnector.Heroku.delete_addon(account, app_id, _addon_id = "ssl:endpoint")

    :ok
  end
end
