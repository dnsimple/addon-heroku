defmodule HerokuConnector.Heroku do
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
