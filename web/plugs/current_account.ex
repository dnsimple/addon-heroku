defmodule HerokuConnector.Plug.CurrentAccount do
  import Plug.Conn
  require Logger

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
            assign(conn, :current_account, HerokuConnector.Heroku.refresh_access_token(account))
        end
    end
  end

  def current_account(conn) do
    case conn.assigns[:current_account] do
      nil -> fetch_account(conn)
      account -> account
    end
  end

  def account_connected?(conn), do: !!current_account(conn)

  def disconnect(conn) do
    account = current_account(conn)
    case account.configuration["webhook_id"] do
      nil -> :ok
      webhook_id -> HerokuConnector.Dnsimple.delete_webhook(account, webhook_id)
    end
    delete_session(conn, :account_id)
  end

  defp fetch_account(conn) do
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
