defmodule Heroku.ConnectionServiceTest do
  use HerokuConnector.ServiceCase

  alias HerokuConnector.Connection
  alias HerokuConnector.ConnectionService
  alias HerokuConnector.Account

  @valid_attrs %{dnsimple_domain_id: "123", heroku_app_id: "ABC"}
  @invalid_attrs %{}

  setup do
    {:ok, account} = Account.create(%Account{dnsimple_account_id: "1"})
    {:ok, account: account}
  end

  # External integration
  test "connect", %{account: account} do
    connection = Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    {:ok, _} = ConnectionService.connect(connection)
  end

  test "reconnect", %{account: account} do
    new_domain_id = "123"
    connection = Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    changeset = Connection.changeset(connection, %{@valid_attrs| dnsimple_domain_id: new_domain_id})
    {:ok, []} = ConnectionService.reconnect(changeset)
  end

  test "disconnect!", %{account: account} do
    connection_data = %HerokuConnector.Connection.ConnectionData{dnsimple_record_ids: [1]}
    connection = Connection.create!(%Connection{account_id: account.id, connection_data: connection_data}, @valid_attrs)
    connection = ConnectionService.disconnect!(connection)
    assert connection != nil
    assert connection.connection_data.dnsimple_record_ids == []
  end
end
