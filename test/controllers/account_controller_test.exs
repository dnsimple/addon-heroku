defmodule HerokuConnector.AccountControllerTest do
  use HerokuConnector.ConnCase

  alias HerokuConnector.Account

  setup do
    {:ok, account} = Account.create(%Account{dnsimple_account_id: "1", heroku_account_id: "2"})
    {:ok, account: account}
  end

  test "disconnects account", %{conn: conn, account: account} do
    conn =  conn |> assign(:current_account, account) |> delete(account_path(conn, :delete))
    assert redirected_to(conn) == connection_path(conn, :index)
  end
end
