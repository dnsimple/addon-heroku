defmodule HerokuConnector.HerokuOauthController do
  use HerokuConnector.Web, :controller

  alias HerokuConnector.Account

  @state "12345678"

  def new(conn, _params) do
    oauth_params = [state: @state]
    oauth_url = OAuth2.Client.authorize_url!(client(), oauth_params)
    redirect(conn, external: oauth_url)
  end

  def create(conn, %{"code" => code}) do
    case OAuth2.Client.get_token(client(), client_secret: client().client_secret, code: code, state: @state) do
      {:ok, response} ->
        access_token = response.token.access_token
        happi_client = Happi.api_client(api_key: access_token)
        heroku_account = Happi.get(happi_client, Happi.Heroku.Account, nil)
        account = Account.get!(get_session(conn, :account_id))

        epoch = {{1970, 1, 1}, {0, 0, 0}}

        # Is there a better way to handle calculating when the access
        # token expires?
        expires_at = response.token.expires_at
        |> Kernel.+(:calendar.datetime_to_gregorian_seconds(epoch))
        |> :calendar.gregorian_seconds_to_datetime
        |> Ecto.DateTime.from_erl

        changeset = Account.changeset(account, %{
          "heroku_account_email" => heroku_account.email,
          "heroku_account_id" => heroku_account.id,
          "heroku_access_token" => access_token,
          "heroku_access_token_expires_at" => expires_at,
          "heroku_refresh_token" => response.token.refresh_token
        })
        Account.update!(changeset)

        conn
        |> redirect(to: connection_path(conn, :index))
      {:error, error} ->
        IO.inspect(error)
        raise "OAuth authentication failed: #{inspect error}"
    end
  end

  defp client do
    IO.inspect HerokuConnector.Heroku.oauth_client
  end

end
