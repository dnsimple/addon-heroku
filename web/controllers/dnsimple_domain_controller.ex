defmodule HerokuConnector.DnsimpleDomainController do
  use HerokuConnector.Web, :controller

  plug HerokuConnector.Plug.CurrentAccount

  def index(conn, _params) do
    account = conn.assigns[:current_account]
    domains = HerokuConnector.Dnsimple.domains(account) |> Enum.map(&(&1.name))
    json conn, %{domains: domains}
  end

end
