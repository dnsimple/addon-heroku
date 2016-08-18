defmodule HerokuConnector.WebhookController do
  use HerokuConnector.Web, :controller

  require Logger

  @doc """
  Handle inbound webhook messages.
  """
  def handle(conn, %{"name" => name, "request_identifier" => request_identifier, "data" => data, "account_id" => _account_id}) do
    HerokuConnector.WebhookRequestTracker.handle(request_identifier, fn() ->
      case name do
        "certificate.issue" ->
          install_certificate(data)
        "certificate.reissue" ->
          install_certificate(data)
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

  defp install_certificate(data) do
    # If the account has a connection with the certificate name
    # And the connection has a Heroku SSL endpoint
    # Use https://devcenter.heroku.com/articles/platform-api-reference#ssl-endpoint-update to update the cert
    Logger.info("Installing certificate #{inspect data}")
  end
end
