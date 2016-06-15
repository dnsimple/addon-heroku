defmodule HerokuConnector.PageControllerTest do
  use HerokuConnector.ConnCase

  alias HerokuConnector.Account

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HerokuConnector.Repo)
  end

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert redirected_to(conn) == dnsimple_oauth_path(conn, :new)
  end

  test "account exists GET /", %{conn: conn} do
    account = Account.create!(%Account{dnsimple_account_id: "1", heroku_account_id: "1"})
    conn = assign(conn, :current_account, account)
    conn = get conn, "/"
    assert redirected_to(conn) == connection_path(conn, :index)
  end

  test "account exists but heroku account id is empty", %{conn: conn} do
    account = Account.create!(%Account{dnsimple_account_id: "1"})
    conn = assign(conn, :current_account, account)
    conn = get conn, "/"
    assert redirected_to(conn) == heroku_oauth_path(conn, :new)
  end
end
