defmodule HerokuConnector.Heroku do
  use Timex

  alias HerokuConnector.Account

  # Functions to get Heroku data.

  @doc """
  Get all Heroku apps for the given `account`.
  """
  def apps(account) do
    app_service.list(client(account))
  end

  @doc """
  Get the application from the `account` with the given `app_id`.
  """
  def app(account, app_id) do
    app_service.get(client(account), app_id)
  end

  def create_domains(account, app_id, hostnames) do
    Enum.map(hostnames, fn(hostname) ->
      domain_service.create(client(account, app_id), %{"hostname" => hostname})
    end)
  end

  def delete_domains(account, app_id, domain_ids) do
    Enum.map(domain_ids, fn(domain_id) ->
      domain_service.delete(client(account, app_id), domain_id)
    end)
  end

  @doc """
  Get the client for the given account.
  """
  def client(account, app \\ nil) do
    Happi.api_client(api_key: account.heroku_access_token, app: app)
  end

  defp app_service do
    Application.get_env(:heroku_connector, :heroku_apps_service, Happi.Heroku.App)
  end

  defp domain_service do
    Application.get_env(:heroku_connector, :heroku_domains_service, Happi.Heroku.Domain)
  end


  # OAuth2 functionality

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

end
