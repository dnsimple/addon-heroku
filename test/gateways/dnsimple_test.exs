defmodule HerokuConnector.DnsimpleTest do
  use HerokuConnector.GatewayCase

  alias HerokuConnector.Account

  setup do
    {:ok, account: %Account{}}
  end

  test "domains", %{account: account} do
    domains = HerokuConnector.Dnsimple.domains(account)
    assert domains == []
  end

end
