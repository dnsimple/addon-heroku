defmodule HerokuConnector.Dnsimple.OauthMock do
  def exchange_authorization_for_token(_client, _attributes) do
    {:ok, %Dnsimple.Response{data: %{access_token: "access-token"}}}
  end
end

defmodule HerokuConnector.Dnsimple.IdentityMock do
  def whoami(_client) do
    {:ok, %Dnsimple.Response{data: %{account: %{"id" => 1}}}}
  end
end

defmodule HerokuConnector.Dnsimple.DomainsMock do
  def domains(_client, _opts) do
    {:ok, %Dnsimple.Response{data: []}}
  end

  def domain(_client, _account_id, name) do
    {:ok, %Dnsimple.Response{data: %Dnsimple.Domain{name: name}}}
  end
end

defmodule HerokuConnector.Dnsimple.DomainCertificatesMock do
  def certificates(_client, _account_id, _name) do
    {:ok, %Dnsimple.Response{data: []}}
  end

  def active_certificates(_client, _account_id, _name) do
    {:ok, %Dnsimple.Response{data: []}}
  end

  def download(_client, _account_id, _name, _certificate_id) do
    {:ok, %Dnsimple.Response{data: %Dnsimple.Certificate{chain: "certificate-chain"}}}
  end

  def private_key(_client, _account_id, _name, _certificate_id) do
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
  def create_record(_client, _account_id, _zone_name, attributes) do
    {:ok, %Dnsimple.Response{data: attributes}}
  end

  def delete_record(_client, _account_id, _zone_name, id) do
    id
  end
end
