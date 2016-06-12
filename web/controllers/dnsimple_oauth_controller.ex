defmodule HerokuConnector.DnsimpleOauthController do
  use HerokuConnector.Web, :controller

  @state "12345678"

  def new(conn, _params) do
    client    = %Dnsimple.Client{}
    client_id = Application.fetch_env!(:heroku_connector, :dnsimple_client_id)
    oauth_url = Dnsimple.OauthService.authorize_url(client, client_id, state: @state)
    redirect(conn, external: oauth_url)
  end

  def create(conn, params) do
    client = %Dnsimple.Client{}
    attributes = %{
      client_id: Application.fetch_env!(:heroku_connector, :dnsimple_client_id),
      client_secret: Application.fetch_env!(:heroku_connector, :dnsimple_client_secret),
      code: params["code"],
      state: params["state"]
    }
    case Dnsimple.OauthService.exchange_authorization_for_token(client, attributes) do
      {:ok, response} ->
        render conn, "welcome.html", access_token: response.data
      {:error, error} ->
        IO.inspect(error)
        raise "OAuth authentication failed: #{inspect(error)}"
    end
  end

end

