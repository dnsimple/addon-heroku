defmodule HerokuConnector.Plug.CurrentAccount do
  import Plug.Conn
  use Timex
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
            assign(conn, :current_account, refresh_account_heroku_token(account))
        end
    end
  end

  def current_account(conn) do
    case conn.assigns[:current_account] do
      nil -> fetch_account(conn)
      account -> account
    end
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

  defp refresh_account_heroku_token(account) do
    if account.heroku_access_token_expires_at != nil and Timex.after?(DateTime.now, account.heroku_access_token_expires_at) do
      case OAuth2.Client.get_token(HerokuConnector.Heroku.oauth_client(OAuth2.Strategy.Refresh), refresh_token: account.heroku_refresh_token) do
        {:ok, response} ->
          changeset = Account.changeset(account, %{
            "heroku_access_token" => response.access_token,
            "heroku_access_token_expires_at" => DateTime.from_seconds(response.expires_at),
            "heroku_refresh_token" => response.refresh_token
          })
          account = Account.update!(changeset)
        {:error, error} ->
          IO.inspect(error)
          raise "OAuth token refresh failed: #{inspect error}"
      end
    end

    account
  end
end
