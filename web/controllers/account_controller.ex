defmodule HerokuConnector.AccountController do
  use HerokuConnector.Web, :controller

  plug HerokuConnector.Plug.CurrentAccount

  def delete(conn, _params) do
    HerokuConnector.Plug.CurrentAccount.disconnect(conn)
    |> render("delete.html")
  end
end
