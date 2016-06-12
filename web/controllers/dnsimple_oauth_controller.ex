defmodule HerokuConnector.DnsimpleOauthController do
  use HerokuConnector.Web, :controller

  alias HerokuConnector.Account

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
        access_token = response.data.access_token
        client = %Dnsimple.Client{access_token: access_token}
        case Dnsimple.IdentityService.whoami(client) do
          {:ok, %Dnsimple.Response{data: data}} ->
            account = Account.find_or_create!(Integer.to_string(data.account["id"]), %{
              "dnsimple_account_email" => data.account["email"],
              "dnsimple_access_token" => access_token
            })

            conn
            |> put_session(:account_id, account.id)
            |> render "welcome.html", account: account
          {:error, error} ->
            IO.inspect(error)
            raise "Failed to retreive account details: #{inspect error}"
        end
      {:error, error} ->
        IO.inspect(error)
        raise "OAuth authentication failed: #{inspect error}"
    end
  end

end

