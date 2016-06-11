defmodule HerokuConnector.PageController do
  use HerokuConnector.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
