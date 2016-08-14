defmodule HerokuConnector.WebhookController do
  use HerokuConnector.Web, :controller

  @doc """
  Handle inbound webhook messages.
  """
  def handle(conn, %{"name" => name, "request_identifier" => request_identifier, "data" => _data, "account_id" => _account_id}) do
    require Logger
    HerokuConnector.WebhookRequestTracker.handle(request_identifier, fn() ->
      Logger.info("Processing webhook #{name}")
    end)

    conn
    |> send_resp(200, "")
  end
end
