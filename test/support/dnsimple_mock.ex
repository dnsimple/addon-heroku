defmodule HerokuConnector.Dnsimple.OauthMock do
  def exchange_authorization_for_token(_client, _attributes) do
    {:ok, %Dnsimple.Response{data: %{access_token: "access-token"}}}
  end
end

defmodule HerokuConnector.Dnsimple.IdentityMock do
  def whoami(_client) do
    {:ok, %Dnsimple.Response{data: %{account: %Dnsimple.Account{id: 1}}}}
  end
end

defmodule HerokuConnector.Dnsimple.DomainsMock do
  def list_domains(_client, _opts) do
    {:ok, %Dnsimple.Response{data: []}}
  end

  def all_domains(_client, _opts) do
    {:ok, []}
  end

  def get_domain(_client, _account_id, name) do
    {:ok, %Dnsimple.Response{data: %Dnsimple.Domain{name: name}}}
  end
end

defmodule HerokuConnector.Dnsimple.DomainCertificatesMock do
  def list_certificates(_client, _account_id, _name) do
    {:ok, %Dnsimple.Response{data: []}}
  end

  def get_certificate(_client, _account_id, _name, certificate_id) do
    {:ok, %Dnsimple.Response{data: %Dnsimple.Certificate{id: certificate_id}}}
  end

  def download_certificate(_client, _account_id, _name, _certificate_id) do
    {:ok, %Dnsimple.Response{data: %Dnsimple.Certificate{chain: "certificate-chain"}}}
  end

  def get_certificate_private_key(_client, _account_id, _name, _certificate_id) do
    {:ok, %Dnsimple.Response{data: %Dnsimple.Certificate{private_key: "private-key"}}}
  end
end

defmodule HerokuConnector.Dnsimple.DomainServicesMock do
  def applied_services(_client, _account_id, _name) do
    {:ok, %Dnsimple.Response{data: []}}
  end

  def apply_service(_client, _account_id, _name, _service_id) do
    :ok
  end

  def unapply_service(_client, _account_id, _name, _service_id) do
    :ok
  end
end

defmodule HerokuConnector.Dnsimple.WebhooksMock do
  def create_webhook(_client, _account_id, _webhook_url) do
    {:ok, %Dnsimple.Response{data: %Dnsimple.Webhook{}}}
  end
end

defmodule HerokuConnector.Dnsimple.ZonesMock do
  def create_zone_record(_client, _account_id, _zone_name, attributes) do
    {:ok, %Dnsimple.Response{data: struct(Dnsimple.ZoneRecord, attributes)}}
  end

  def delete_zone_record(_client, _account_id, _zone_name, id) do
    id
  end
end
