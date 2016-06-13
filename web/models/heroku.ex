defmodule HerokuConnector.Heroku do
  use Timex

  alias HerokuConnector.Account

  def oauth_client(strategy \\ OAuth2.Strategy.AuthCode) do
    OAuth2.Client.new([
      strategy: strategy,
      client_id: Application.fetch_env!(:heroku_connector, :heroku_client_id),
      client_secret: Application.fetch_env!(:heroku_connector, :heroku_client_secret),
      site: "https://heroku.com",
      redirect_uri: "http://localhost:4000/heroku/callback",
      authorize_url: "https://id.heroku.com/oauth/authorize",
      token_url: "https://id.heroku.com/oauth/token"
    ])
  end

  def refresh_access_token(account) do
    case access_token_expired?(account) do
      true -> do_refresh_access_token(account)
      false -> account
    end
  end

  defp access_token_expired?(account) do
    account.heroku_access_token_expires_at != nil and Timex.after?(DateTime.now, account.heroku_access_token_expires_at)
  end

  defp do_refresh_access_token(account) do
    case OAuth2.Client.get_token(oauth_client(OAuth2.Strategy.Refresh), refresh_token: account.heroku_refresh_token) do
      {:ok, response} ->
        changeset = Account.changeset(account, %{
          "heroku_access_token" => response.access_token,
          "heroku_access_token_expires_at" => DateTime.from_seconds(response.expires_at),
          "heroku_refresh_token" => response.refresh_token
        })
        Account.update!(changeset)
      {:error, error} ->
        IO.inspect(error)
        raise "OAuth token refresh failed: #{inspect error}"
    end
  end

  def apps(account) do
    app_service.list(client(account))
  end

  def client(account) do
    Happi.api_client(api_key: account.heroku_access_token)
  end

  defp app_service do
    Application.get_env(:heroku_connector, :heroku_apps_service, Happi.Heroku.App)
  end

end
