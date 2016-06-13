defmodule HerokuConnector.Dnsimple do
  def domains(account) do
    dnsimple_domains = case domain_service.domains(client(account), account.id) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to retreive domains: #{inspect error}"
    end
  end

  def client(account) do
    %Dnsimple.Client{access_token: account.dnsimple_access_token}
  end

  defp domain_service do
    Application.get_env(:heroku_connector, :dnsimple_domains_service, Dnsimple.DomainsService)
  end
end
