defmodule HerokuConnector.HerokuApplicationController do
  use HerokuConnector.Web, :controller

  plug HerokuConnector.Plug.CurrentAccount

  def index(conn, _params) do
    account = conn.assigns[:current_account]
    apps = HerokuConnector.Heroku.apps(account) |> Enum.map(&(&1.name))
    json conn, %{apps: apps}
  end

end

