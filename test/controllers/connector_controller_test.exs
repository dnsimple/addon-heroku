defmodule HerokuConnector.ConnectorControllerTest do
  use HerokuConnector.ConnCase

  alias HerokuConnector.Connector
  alias HerokuConnector.Account

  @valid_attrs %{dnsimple_domain_id: "123", heroku_app_id: "ABC"}
  @invalid_attrs %{}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HerokuConnector.Repo)
    {:ok, account} = Account.create(%Account{dnsimple_account_id: "1", heroku_account_id: "2"})
    {:ok, account: account}
  end

  test "lists all entries on index", %{conn: conn, account: account} do
    conn = conn |> assign(:current_account, account) |> get(connector_path(conn, :index))
    assert html_response(conn, 200) =~ "Listing connectors"
  end

  test "renders form for new resources", %{conn: conn, account: account} do
    conn = conn |> assign(:current_account, account) |> get(connector_path(conn, :new))
    assert html_response(conn, 200) =~ "New connector"
  end

  test "creates resource and redirects when data is valid", %{conn: conn, account: account} do
    conn = conn |> assign(:current_account, account) |>  post(connector_path(conn, :create), connector: @valid_attrs)
    assert redirected_to(conn) == connector_path(conn, :index)
    assert Repo.get_by(Connector, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn, account: account} do
    conn = conn |> assign(:current_account, account) |> post(connector_path(conn, :create), connector: @invalid_attrs)
    assert html_response(conn, 200) =~ "New connector"
  end

  test "shows chosen resource", %{conn: conn, account: account} do
    connector = Repo.insert! %Connector{account_id: account.id}
    conn = conn |> assign(:current_account, account) |> get(connector_path(conn, :show, connector))
    assert html_response(conn, 200) =~ "Show connector"
  end

  test "renders page not found when id is nonexistent", %{conn: conn, account: account} do
    assert_error_sent 404, fn ->
      conn |> assign(:current_account, account) |> get(connector_path(conn, :show, -1))
    end
  end

  test "renders form for editing chosen resource", %{conn: conn, account: account} do
    connector = Repo.insert! %Connector{account_id: account.id}
    conn = conn |> assign(:current_account, account) |> get(connector_path(conn, :edit, connector))
    assert html_response(conn, 200) =~ "Edit connector"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn, account: account} do
    connector = Repo.insert! %Connector{account_id: account.id}
    conn =  conn |> assign(:current_account, account) |> put(connector_path(conn, :update, connector), connector: @valid_attrs)
    assert redirected_to(conn) == connector_path(conn, :show, connector)
    assert Repo.get_by(Connector, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn, account: account} do
    connector = Repo.insert! %Connector{account_id: account.id}
    conn = conn |> assign(:current_account, account) |> put(connector_path(conn, :update, connector), connector: @invalid_attrs)
    assert html_response(conn, 200) =~ "Edit connector"
  end

  test "deletes chosen resource", %{conn: conn, account: account} do
    connector = Repo.insert! %Connector{account_id: account.id}
    conn =  conn |> assign(:current_account, account) |> delete(connector_path(conn, :delete, connector))
    assert redirected_to(conn) == connector_path(conn, :index)
    refute Repo.get(Connector, connector.id)
  end
end
