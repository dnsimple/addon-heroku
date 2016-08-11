defmodule HerokuConnector.WebhookController do
  use HerokuConnector.Web, :controller

  @doc """
  Handle inbound webhook messages.
  """
  def handle(conn, _params) do
    # IO.inspect params

    conn
    |> send_resp(200, "")
  end
end
