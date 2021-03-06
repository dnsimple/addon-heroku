defmodule HerokuConnector.ConnectionControllerTest do
  use HerokuConnector.ConnCase

  alias HerokuConnector.Connection
  alias HerokuConnector.Connection.ConnectionData
  alias HerokuConnector.Account

  @valid_attrs %{dnsimple_domain_id: "123", heroku_app_id: "ABC"}
  @invalid_attrs %{}

  setup do
    {:ok, account} = Account.create(%Account{dnsimple_account_id: "1", heroku_account_id: "2"})
    {:ok, account: account}
  end

  test "redirects to new connection if none present", %{conn: conn, account: account} do
    conn = conn |> assign(:current_account, account) |> get(connection_path(conn, :index))
    assert redirected_to(conn) == connection_path(conn, :new)
  end

  test "lists all entries on index", %{conn: conn, account: account} do
    Repo.insert! %Connection{account_id: account.id}
    conn = conn |> assign(:current_account, account) |> get(connection_path(conn, :index))
    assert html_response(conn, 200) =~ "Listing connections"
  end

  test "renders form for new resources", %{conn: conn, account: account} do
    conn = conn |> assign(:current_account, account) |> get(connection_path(conn, :new))
    assert html_response(conn, 200) =~ "New connection"
  end

  test "creates resource and redirects when data is valid and no certificates are present", %{conn: conn, account: account} do
    conn = conn |> assign(:current_account, account) |> post(connection_path(conn, :create), connection: @valid_attrs)
    connection = Repo.get_by(Connection, @valid_attrs)
    assert connection
    assert redirected_to(conn) == connection_path(conn, :index)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn, account: account} do
    conn = conn |> assign(:current_account, account) |> post(connection_path(conn, :create), connection: @invalid_attrs)
    assert html_response(conn, 200) =~ "New connection"
  end

  test "connects and redirects to index when no certificates are present", %{conn: conn, account: account} do
    connection = Repo.insert! %Connection{account_id: account.id}
    conn = conn |> assign(:current_account, account) |> get(connection_path(conn, :connect, connection))
    assert redirected_to(conn) == connection_path(conn, :index)
  end

  test "shows chosen resource", %{conn: conn, account: account} do
    connection = Repo.insert! %Connection{account_id: account.id}
    conn = conn |> assign(:current_account, account) |> get(connection_path(conn, :show, connection))
    assert html_response(conn, 200) =~ "Show connection"
  end

  test "renders page not found when id is nonexistent", %{conn: conn, account: account} do
    assert_error_sent 404, fn ->
      conn |> assign(:current_account, account) |> get(connection_path(conn, :show, -1))
    end
  end

  test "renders form for editing chosen resource", %{conn: conn, account: account} do
    connection = Repo.insert! %Connection{account_id: account.id}
    conn = conn |> assign(:current_account, account) |> get(connection_path(conn, :edit, connection))
    assert html_response(conn, 200) =~ "Edit connection"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn, account: account} do
    connection = Repo.insert! %Connection{account_id: account.id, connection_data: %ConnectionData{}}
    conn =  conn |> assign(:current_account, account) |> put(connection_path(conn, :update, connection), connection: @valid_attrs)
    assert redirected_to(conn) == connection_path(conn, :show, connection)
    assert Repo.get_by(Connection, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn, account: account} do
    connection = Repo.insert! %Connection{account_id: account.id, connection_data: %ConnectionData{}}
    conn = conn |> assign(:current_account, account) |> put(connection_path(conn, :update, connection), connection: @invalid_attrs)
    assert html_response(conn, 200) =~ "Edit connection"
  end

  test "deletes chosen resource", %{conn: conn, account: account} do
    connection = Repo.insert! %Connection{account_id: account.id, connection_data: %ConnectionData{}}
    conn =  conn |> assign(:current_account, account) |> delete(connection_path(conn, :delete, connection))
    assert redirected_to(conn) == connection_path(conn, :index)
    refute Repo.get(Connection, connection.id)
  end
end
