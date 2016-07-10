defmodule HerokuConnector.Dnsimple.OauthServiceMock do
  def exchange_authorization_for_token(_client, _attributes) do
    {:ok, %Dnsimple.Response{data: %{access_token: "access-token"}}}
  end
end

defmodule HerokuConnector.Dnsimple.IdentityServiceMock do
  def whoami(_client) do
    {:ok, %Dnsimple.Response{data: %{account: %{"id" => 1}}}}
  end
end

defmodule HerokuConnector.Dnsimple.DomainsServiceMock do
  def domains(_client, _opts) do
    {:ok, %Dnsimple.Response{data: []}}
  end

  def domain(_client, _account_id, name) do
    {:ok, %Dnsimple.Response{data: %Dnsimple.Domain{name: name}}}
  end
end

defmodule HerokuConnector.Dnsimple.ZonesServiceMock do
  def create_record(_client, _account_id, _zone_name, attributes) do
    {:ok, %Dnsimple.Response{data: attributes}}
  end

  def delete_records(_client, _account_id, _zone_name, _ids) do
    []
  end
end
