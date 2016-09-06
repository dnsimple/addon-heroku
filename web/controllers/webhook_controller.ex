defmodule HerokuConnector.WebhookController do
  use HerokuConnector.Web, :controller

  require Logger

  @doc """
  Handle inbound webhook messages.
  """
  def handle(conn, %{"name" => name, "request_identifier" => request_identifier, "data" => data, "account_id" => account_id}) do
    HerokuConnector.WebhookRequestTracker.handle(request_identifier, fn() ->
      case name do
        "certificate.issue" ->
          install_certificate(account_id, data)
        "certificate.reissue" ->
          install_certificate(account_id, data)
        _ -> :ok
      end
      Logger.info("Processing webhook #{name}")
    end)

    conn
    |> send_resp(200, "")
  end

  def handle(conn, _params) do
    conn
    |> send_resp(200, "")
  end

  defp install_certificate(account_id, data) do
    # If the account has a connection with the certificate name
    # And the connection has a Heroku SSL endpoint
    # Use https://devcenter.heroku.com/articles/platform-api-reference#ssl-endpoint-update to update the cert

    case HerokuConnector.Account.get_by_dnsimple_account_id(account_id) do
      nil ->
        Logger.error("Account not found for id #{account_id}")
      account ->
        Logger.info("Found account: #{inspect account}, refreshing token")
        account = HerokuConnector.Heroku.refresh_access_token(account)
        Logger.info("Heroku token refreshed")
        dnsimple_domain_id = data["certificate"]["domain_id"]
        domain = HerokuConnector.Dnsimple.domain(account, dnsimple_domain_id)

        case HerokuConnector.Connection.get_by_dnsimple_domain_id(domain.name) do
          nil -> :ok
          connection ->
            app_id = connection.heroku_app_id
            domain_name = connection.dnsimple_domain_id
            dnsimple_certificate_id = data["certificate"]["id"]
            if HerokuConnector.Heroku.addon_enabled?(account, app_id, "ssl:endpoint") do
              ssl_endpoint_id = connection.connection_data.ssl_endpoint_id
              HerokuConnector.ConnectionService.update_heroku_ssl_endpoint(account, domain_name, app_id, dnsimple_certificate_id, ssl_endpoint_id)
            end
        end
    end
  end
end
