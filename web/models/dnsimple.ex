defmodule HerokuConnector.Dnsimple do
  def domains(account) do
    dnsimple_domains = case domain_service.domains(client(account), account.id) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to retreive domains: #{inspect error}"
    end
  end

  def domain(account, id) do
    dnsimple_domain = case domain_service.domain(client(account), account.id, id) do
      {:ok, response} -> response.data
      {:error, error} ->
        IO.inspect(error)
        raise "Failed to retreive domain: #{inspect error}"
    end
  end

  def create_records(account, zone_name, records) do
    c = client(account)
    zs = zone_service
    Enum.map(records, &(zs.create_record(c, account.id, zone_name, &1)))
  end

  def client(account) do
    %Dnsimple.Client{access_token: account.dnsimple_access_token}
  end

  defp domain_service do
    Application.get_env(:heroku_connector, :dnsimple_domains_service, Dnsimple.DomainsService)
  end

  defp zone_service do
    Application.get_env(:heroku_connector, :dnsimple_zones_service, Dnsimple.ZonesService)
  end
end
