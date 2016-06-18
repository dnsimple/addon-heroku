defmodule HerokuConnector.Dnsimple do
  # OAuth

  def authorize_url(client, client_id, options) do
    Dnsimple.OauthService.authorize_url(client, client_id, state: options[:state])
  end

  def exchange_authorization_for_token(client, attributes) do
    oauth_service.exchange_authorization_for_token(client, attributes)
  end

  # Identity

  def whoami(client) do
    identity_service.whoami(client)
  end

  # Domains

  def domains(account) do
    case domain_service.domains(client(account), account.id) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to retreive domains: #{inspect error}"
    end
  end

  def domain(account, id) do
    case domain_service.domain(client(account), account.id, id) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to retreive domain: #{inspect error}"
    end
  end

  # Records

  def create_records(account, zone_name, records) do
    c = client(account)
    zs = zone_service
    Enum.map(records, &(zs.create_record(c, account.id, zone_name, &1)))
  end

  def delete_records(account, zone_name, record_ids) do
    c = client(account)
    zs = zone_service
    Enum.map(record_ids, &(zs.delete_record(c, account.id, zone_name, &1)))
  end

  # Client for account

  def client(account) do
    %Dnsimple.Client{access_token: account.dnsimple_access_token}
  end

  # Service modules

  defp oauth_service do
    Application.get_env(:heroku_connector, :dnsimple_oauth_service, Dnsimple.OauthService)
  end

  defp identity_service do
    Application.get_env(:heroku_connector, :dnsimple_identity_service, Dnsimple.IdentityService)
  end

  defp domain_service do
    Application.get_env(:heroku_connector, :dnsimple_domains_service, Dnsimple.DomainsService)
  end

  defp zone_service do
    Application.get_env(:heroku_connector, :dnsimple_zones_service, Dnsimple.ZonesService)
  end
end
