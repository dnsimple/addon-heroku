defmodule HerokuConnector.Plug.CurrentAccount do
  import Plug.Conn

  alias HerokuConnector.Account

  def init(opts), do: opts

  def call(conn, _opts) do
    case current_account(conn) do
      nil ->
        conn
        |> Phoenix.Controller.redirect(to: HerokuConnector.Router.Helpers.dnsimple_oauth_path(conn, :new))
        |> halt
      account ->
        case account.heroku_account_id do
          nil ->
            conn
            |> Phoenix.Controller.redirect(to: HerokuConnector.Router.Helpers.heroku_oauth_path(conn, :new))
            |> halt
          _ ->
            assign(conn, :current_account, account)
        end
    end
  end

  def current_account(conn) do
    case conn.assigns[:current_account] do
      nil -> fetch_account(conn)
      account -> account
    end
  end

  def fetch_account(conn) do
    case get_session(conn, :account_id) do
      nil -> nil
      account_id ->
        case Account.get(account_id) do
          nil -> nil
          account -> account
        end
    end
  end
end
