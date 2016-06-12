defmodule HerokuConnector.PageController do
  use HerokuConnector.Web, :controller

  plug HerokuConnector.Plug.CurrentAccount

  def index(conn, _params) do
    render conn, "index.html", account: conn.assigns[:current_account]
  end
end
