defmodule HerokuConnector.AccountTest do
  use HerokuConnector.ModelCase, async: true

  alias HerokuConnector.Account

  @valid_attrs %{
    email: "john.doe@example.com",
    dnsimple_access_token: "dnsimple-token",
    heroku_access_token: "heroku-token",
    heroku_access_token_expires_at: Ecto.DateTime.cast!("2020-01-01 00:00:00"),
    heroku_refresh_token: "heroku-refresh"
  }

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "create with valid attributes" do
    {:ok, account} = Account.create(%Account{}, @valid_attrs) 
    assert account.email == @valid_attrs[:email]
    assert Repo.get(Account, account.id) == account
  end

  test "create! with valid attributes" do
    account = Account.create!(%Account{}, @valid_attrs)
    assert account.email == @valid_attrs[:email]
    assert Repo.get(Account, account.id) == account
  end

  test "find or create with valid email" do
    {:ok, account} = Account.find_or_create(@valid_attrs[:email])
    assert account.email == @valid_attrs[:email]
    assert Repo.get(Account, account.id) == account
  end

  test "find or create! with valid email" do
    account = Account.find_or_create!(@valid_attrs[:email])
    assert account.email == @valid_attrs[:email]
    assert Repo.get(Account, account.id) == account
  end

  test "update with valid attributes" do
    new_email = "another-email@example.com"
    account = Account.create!(%Account{}, @valid_attrs)
    changeset = Account.changeset(account, %{@valid_attrs| email: new_email})
    {:ok, account} = Account.update(changeset)
    assert account.email == new_email
  end

  test "update! with valid attributes" do
    new_email = "another-email@example.com"
    account = Account.create!(%Account{}, @valid_attrs)
    changeset = Account.changeset(account, %{@valid_attrs| email: new_email})
    account = Account.update!(changeset)
    assert account.email == new_email
  end

  test "delete" do
    account = Account.create!(%Account{}, @valid_attrs)
    {:ok, account} = Account.delete(account)
    assert Repo.get(Account, account.id) == nil
  end
end
