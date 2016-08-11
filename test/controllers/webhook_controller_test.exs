defmodule HerokuConnector.WebhookControllerTest do
  use HerokuConnector.ConnCase

  alias HerokuConnector.Connection
  alias HerokuConnector.Account

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HerokuConnector.Repo)
    {:ok, account} = Account.create(%Account{dnsimple_account_id: "1", heroku_account_id: "2"})
    {:ok, account: account}
  end

  test "POST /", %{conn: conn, account: account} do
    connection = Repo.insert! %Connection{account_id: account.id}
    conn = conn |> post(webhook_path(conn, :handle, connection.id), data: {})
    assert conn.status == 200
  end
end
