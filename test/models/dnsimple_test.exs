defmodule HerokuConnector.DnsimpleTest do
  use HerokuConnector.ModelCase

  alias HerokuConnector.Account

  setup do
    {:ok, account: %Account{}}
  end

  test "domains", %{account: account} do
    domains = HerokuConnector.Dnsimple.domains(account)
    assert domains == []
  end

end
