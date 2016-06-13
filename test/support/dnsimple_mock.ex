defmodule HerokuConnector.Dnsimple.DomainsServiceMock do
  def domains(_client, _opts) do
    {:ok, %Dnsimple.Response{data: []}}
  end
end
