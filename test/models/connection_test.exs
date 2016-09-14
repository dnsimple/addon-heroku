defmodule HerokuConnector.ConnectionTest do
  use HerokuConnector.ModelCase

  alias HerokuConnector.Connection
  alias HerokuConnector.Account

  @valid_attrs %{dnsimple_domain_id: "example.com", heroku_app_id: "ABC"}
  @invalid_attrs %{}

  setup do
    {:ok, account} = Account.create(%Account{dnsimple_account_id: "1"})
    {:ok, account: account}
  end

  test "create with valid attributes", %{account: account} do
    {:ok, connection} = Connection.create(%Connection{account_id: account.id}, @valid_attrs)
    assert connection.dnsimple_domain_id == @valid_attrs[:dnsimple_domain_id]
    assert Repo.get(Connection, connection.id) |> Repo.preload([:account]) == connection
  end

  test "create! with valid attributes", %{account: account} do
    connection = Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    assert connection.dnsimple_domain_id == @valid_attrs[:dnsimple_domain_id]
    assert Repo.get(Connection, connection.id) |> Repo.preload([:account]) == connection
  end

  test "get with existing id", %{account: account} do
    connection = Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    assert Connection.get(account, connection.id).id == connection.id
  end

  test "get with a non-existant id", %{account: account} do
    assert Connection.get(account, "0") == nil
  end

  test "get! with existing id", %{account: account} do
    connection = Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    assert Connection.get!(account, connection.id).id == connection.id
  end

  test "get! with a non-existant id", %{account: account} do
    assert_raise Ecto.NoResultsError, fn ->
      Connection.get!(account, "0")
    end
  end

  test "get_by_dnsimple_domain_id with an existing domain id", %{account: account} do
    connection = Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    assert Connection.get_by_dnsimple_domain_id("example.com").id == connection.id
  end

  test "get_by_dnsimple_domain_id with a non-existant domain id", %{account: _account} do
    assert Connection.get_by_dnsimple_domain_id("0") == nil
  end

  test "get_by_dnsimple_domain_id! with an existing domain id", %{account: account} do
    connection = Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    assert Connection.get_by_dnsimple_domain_id!("example.com").id == connection.id
  end

  test "get_by_dnsimple_domain_id! with a non-existent domain id", %{account: _account} do
    assert_raise Ecto.NoResultsError, fn ->
      Connection.get_by_dnsimple_domain_id!("0")
    end
  end

  test "all", %{account: account} do
    Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    assert length(Connection.all(account)) == 1
  end

  test "changeset with valid attributes", %{account: account} do
    changeset = Connection.changeset(%Connection{account_id: account.id}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes", %{account: account} do
    changeset = Connection.changeset(%Connection{account_id: account.id}, @invalid_attrs)
    refute changeset.valid?
  end

  test "update with valid attributes", %{account: account} do
    new_domain_id = "123"
    connection = Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    changeset = Connection.changeset(connection, %{@valid_attrs| dnsimple_domain_id: new_domain_id})
    {:ok, connection} = Connection.update(changeset)
    assert connection.dnsimple_domain_id == new_domain_id
  end

  test "update! with valid attributes", %{account: account} do
    new_domain_id = "123"
    connection = Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    changeset = Connection.changeset(connection, %{@valid_attrs| dnsimple_domain_id: new_domain_id})
    connection = Connection.update!(changeset)
    assert connection.dnsimple_domain_id == new_domain_id
  end

  test "delete", %{account: account} do
    connection = Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    {:ok, connection} = Connection.delete(connection)
    assert Repo.get(Connection, connection.id) == nil
  end

  test "delete!", %{account: account} do
    connection = Connection.create!(%Connection{account_id: account.id}, @valid_attrs)
    connection = Connection.delete!(connection)
    assert Repo.get(Connection, connection.id) == nil
  end

  
end
