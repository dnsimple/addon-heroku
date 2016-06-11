defmodule HerokuConnector.PageControllerTest do
  use HerokuConnector.ConnCase

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HerokuConnector.Repo)
  end

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
