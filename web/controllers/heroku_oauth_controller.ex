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

        # Is there a better way to handle calculating when the access
        # token expires?
        expires_at = response.expires_at
        |> Kernel.+(:calendar.datetime_to_gregorian_seconds(epoch))
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

        render conn, "welcome.html", account: account
      {:error, error} ->
        IO.inspect(error)
        raise "OAuth authentication failed: #{inspect error}"
    end
  end

  defp client do
    HerokuConnector.Heroku.oauth_client
  end

end
