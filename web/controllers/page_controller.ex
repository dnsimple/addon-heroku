defmodule HerokuConnector.PageController do
  use HerokuConnector.Web, :controller

  alias HerokuConnector.Account

  def index(conn, _params) do
    case get_session(conn, :account_id) do
      nil ->
        redirect conn, to: dnsimple_oauth_path(conn, :new)
      account_id ->
        case Account.get(account_id) do
          nil -> redirect conn, to: dnsimple_oauth_path(conn, :new)
          account -> render conn, "index.html", account: account
        end
    end
  end
end
