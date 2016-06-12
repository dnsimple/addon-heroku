defmodule HerokuConnector.PageControllerTest do
  use HerokuConnector.ConnCase

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HerokuConnector.Repo)
  end

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert redirected_to(conn) == dnsimple_oauth_path(conn, :new)
  end
end
