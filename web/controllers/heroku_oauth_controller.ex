defmodule HerokuConnector.HerokuOauthController do
  use HerokuConnector.Web, :controller

  alias HerokuConnector.Account

  @state "12345678"

  def new(conn, _params) do
    oauth_params = [state: @state]
    oauth_url = OAuth2.Client.authorize_url!(client, oauth_params)
    redirect(conn, external: oauth_url)
  end

  def create(conn, %{"code" => code}) do
    case OAuth2.Client.get_token(client, code: code, state: @state) do
      {:ok, response} ->
        access_token = response.access_token
        client = Happi.api_client(api_key: access_token)
        heroku_account = Happi.get(client, Happi.Heroku.Account, nil)
        account = Account.get!(get_session(conn, :account_id))

        epoch = {{1970, 1, 1}, {0, 0, 0}}

        expires_at = response.expires_at
        |> +(:calendar.datetime_to_gregorian_seconds(epoch))
        |> :calendar.gregorian_seconds_to_datetime
        |> Ecto.DateTime.from_erl

        changeset = Account.changeset(account, %{
          "heroku_account_email" => heroku_account.email,
          "heroku_account_id" => heroku_account.id,
          "heroku_access_token" => access_token,
          "heroku_access_token_expires_at" => expires_at,
          "heroku_refresh_token" => response.refresh_token
        })
        Account.update!(changeset)

        render conn, "welcome.html", access_token: access_token
      {:error, error} ->
        IO.inspect(error)
        raise "OAuth authentication failed: #{inspect error}"
    end
    
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
