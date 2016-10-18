defmodule HerokuConnector.Heroku do
  alias HerokuConnector.Account

  require Logger

  # Apps

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

  # Dynos

  def dynos(account, app_id) do
    dyno_service.list(client(account, app_id))
  end

  # Add-on attachments

  def create_addon(account, app_id, addon_id) do
    addon_service.create(client(account, app_id), %{"plan" => addon_id})
  end

  def delete_addon(account, app_id, addon_id) do
    addon_service.delete(client(account, app_id), addon_id)
  end

  def addon_enabled?(account, app_id, addon_id) do
    case addon_service.get(client(account, app_id), addon_id) do
      %Happi.Heroku.Error{code: 404} -> false
      _ -> true
    end
  end

  # SSL Endpoints

  def create_ssl_endpoint(account, app_id, certificate_chain, private_key) do
    ssl_endpoint_service.create(client(account, app_id), %{"certificate_chain" => certificate_chain, "private_key" => private_key})
  end

  def update_ssl_endpoint(account, app_id, certificate_chain, private_key, ssl_endpoint_id) do
    Logger.info("update ssl endpoint #{inspect ssl_endpoint_id} in app #{app_id}")
    params = %{"certificate_chain" => certificate_chain, "private_key" => private_key}
    result = ssl_endpoint_service.update(client(account, app_id), ssl_endpoint_id, params)
    IO.inspect(result)
  end

  def delete_ssl_endpoint(account, app_id, ssl_endpoint_id) do
    ssl_endpoint_service.delete(client(account, app_id), ssl_endpoint_id)
  end

  # SNI Endpoins

  def create_sni_endpoint(account, app_id, certificate_chain, private_key) do
    sni_endpoint_service.create(client(account, app_id), %{"certificate_chain" => certificate_chain, "private_key" => private_key})
  end

  def update_sni_endpoint(account, app_id, certificate_chain, private_key, endpoint_id) do
    Logger.info("update ssl endpoint #{inspect endpoint_id} in app #{app_id}")
    params = %{"certificate_chain" => certificate_chain, "private_key" => private_key}
    result = sni_endpoint_service.update(client(account, app_id), endpoint_id, params)
    IO.inspect(result)
  end

  def delete_sni_endpoint(account, app_id, endpoint_id) do
    sni_endpoint_service.delete(client(account, app_id), endpoint_id)
  end

  # Domains

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

  # Service adapters

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

  defp dyno_service do
    Application.get_env(:heroku_connector, :heroku_dyno_service, Happi.Heroku.Dyno)
  end

  defp addon_service do
    Application.get_env(:heroku_connector, :heroku_addons_service, Happi.Heroku.Addon)
  end

  defp ssl_endpoint_service do
    Application.get_env(:heroku_connector, :heroku_ssl_endpoints_service, Happi.Heroku.SslEndpoint)
  end

  defp sni_endpoint_service do
    Application.get_env(:heroku_connector, :heroku_sni_endpoints_service, Happi.Heroku.SniEndpoint)
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
    case account.heroku_access_token_expires_at do
      nil -> false
      expires_at -> Ecto.DateTime.compare(Ecto.DateTime.utc, expires_at) == :gt
    end
  end

  defp do_refresh_access_token(account) do
    case OAuth2.Client.get_token(oauth_client(OAuth2.Strategy.Refresh), refresh_token: account.heroku_refresh_token) do
      {:ok, response} ->
        changeset = Account.changeset(account, %{
          "heroku_access_token" => response.token.access_token,
          "heroku_access_token_expires_at" => DateTime.from_unix!(response.token.expires_at),
          "heroku_refresh_token" => response.token.refresh_token
        })
        Account.update!(changeset)
      {:error, error} ->
        IO.inspect(error)
        raise "OAuth token refresh failed: #{inspect error}"
    end
  end

end
