defmodule HerokuConnector.HerokuOauthController do
  use HerokuConnector.Web, :controller

  @state "12345678"

  def new(conn, _params) do
    oauth_params = [state: @state]
    oauth_url = OAuth2.Client.authorize_url!(client, oauth_params)
    redirect(conn, external: oauth_url)
  end

  def create(conn, %{"code" => code}) do
    token = OAuth2.Client.get_token!(client, code: code, state: @state)
    render conn, "welcome.html", access_token: token
  end

  defp client do
    OAuth2.Client.new([
      strategy: OAuth2.Strategy.AuthCode,
      client_id: Application.fetch_env!(:heroku_connector, :heroku_client_id),
      client_secret: Application.fetch_env!(:heroku_connector, :heroku_client_secret),
      site: "https://heroku.com",
      redirect_uri: "http://localhost:4000/heroku/callback",
      authorize_url: "https://id.heroku.com/oauth/authorize",
      token_url: "https://id.heroku.com/oauth/token"
    ])
  end

end
