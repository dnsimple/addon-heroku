defmodule HerokuConnector.ConnectorTest do
  use HerokuConnector.ModelCase

  alias HerokuConnector.Connector
  alias HerokuConnector.Account

  @valid_attrs %{dnsimple_domain_id: "123", heroku_app_id: "ABC"}
  @invalid_attrs %{}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    {:ok, account} = Account.create(%Account{dnsimple_account_id: "1"})
    {:ok, account: account}
  end

  test "changeset with valid attributes", %{account: account} do
    changeset = Connector.changeset(%Connector{account_id: account.id}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes", %{account: account} do
    changeset = Connector.changeset(%Connector{account_id: account.id}, @invalid_attrs)
    refute changeset.valid?
  end
end
