defmodule HerokuConnector.Dnsimple do
  # OAuth

  def authorize_url(client, client_id, options) do
    Dnsimple.Oauth.authorize_url(client, client_id, state: options[:state])
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
    domains_service.all_domains(client(account), account.id)
  end

  def domain(account, id) do
    case domains_service.get_domain(client(account), account.id, id) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to retrieve domain: #{inspect error}"
    end
  end

  # Domain Certificates

  def certificates(account, domain_name) do
    case certificates_service.list_certificates(client(account), account.id, domain_name) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to retrieve certificates: #{inspect error}"
    end
  end

  def active_certificates(account, domain_name) do
    Enum.filter(certificates(account, domain_name), fn(c) -> c.state == "issued" end)
  end

  def download_certificate(account, domain_name, certificate_id) do
    case certificates_service.download_certificate(client(account), account.id, domain_name, certificate_id) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to download certificate: #{inspect error}"
    end
  end

  def private_key(account, domain_name, certificate_id) do
    case certificates_service.private_key(client(account), account.id, domain_name, certificate_id) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to get private key: #{inspect error}"
    end
  end

  # Domain Services

  def applied_services(account, domain_name) do
    case services_service.applied_services(client(account), account.id, domain_name) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to retrieve domain services: #{inspect error}"
    end
  end

  def apply_service(account, domain_name, service_id) do
    case services_service.apply_service(client(account), account.id, domain_name, service_id) do
      {:ok, _response} -> service_id
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to apply service: #{inspect error}"
    end
  end

  def unapply_service(account, domain_name, service_id) do
    case services_service.unapply_service(client(account), account.id, domain_name, service_id) do
      {:ok, _response} -> service_id
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to unapply service: #{inspect error}"
    end
  end

  # Records

  def create_records(account, zone_name, records) do
    c = client(account)
    zs = zones_service
    Enum.map(records, &(zs.create_record(c, account.id, zone_name, &1)))
  end

  def delete_records(account, zone_name, record_ids) do
    c = client(account)
    zs = zones_service
    Enum.map(record_ids, &(zs.delete_record(c, account.id, zone_name, &1)))
  end

  # Webhooks

  def create_webhook(account, webhook_url) do
    case webhooks_service.create_webhook(client(account), account.id, %{url: webhook_url}) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to create webhook: #{inspect error}"
    end
  end

  def delete_webhook(account, webhook_id) do
    webhooks_service.delete_webhook(client(account), account.id, webhook_id)
  end

  def delete_webhook!(account, webhook_id) do
    case webhooks_service.delete_webhook(client(account), account.id, webhook_id) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to delete webhook: #{inspect error}"
    end
  end

  # Client for account

  def client(account) do
    %Dnsimple.Client{access_token: account.dnsimple_access_token}
  end

  # Service modules

  defp oauth_service do
    Application.get_env(:heroku_connector, :dnsimple_oauth_service, Dnsimple.Oauth)
  end

  defp identity_service do
    Application.get_env(:heroku_connector, :dnsimple_identity_service, Dnsimple.Identity)
  end

  defp domains_service do
    Application.get_env(:heroku_connector, :dnsimple_domains_service, Dnsimple.Domains)
  end

  defp certificates_service do
    Application.get_env(:heroku_connector, :dnsimple_domain_certificates_service, Dnsimple.Certificates)
  end

  defp services_service do
    Application.get_env(:heroku_connector, :dnsimple_domain_services_service, Dnsimple.Services)
  end

  defp webhooks_service do
    Application.get_env(:heroku_connector, :dnsimple_webhooks_service, Dnsimple.Webhooks)
  end

  defp zones_service do
    Application.get_env(:heroku_connector, :dnsimple_zones_service, Dnsimple.Zones)
  end
end
