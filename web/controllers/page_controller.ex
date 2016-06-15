defmodule HerokuConnector.PageController do
  use HerokuConnector.Web, :controller

  plug HerokuConnector.Plug.CurrentAccount

  def index(conn, _params) do
    redirect conn, to: connection_path(conn, :index)
  end
end
