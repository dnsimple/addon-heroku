defmodule HerokuConnector.ConnectionController do
  use HerokuConnector.Web, :controller

  alias HerokuConnector.Connection

  plug HerokuConnector.Plug.CurrentAccount
  plug :scrub_params, "connection" when action in [:create, :update]

  def index(conn, _params) do
    account = conn.assigns[:current_account]
    connections = Connection.all(account)
    render(conn, "index.html", connections: connections)
  end

  def new(conn, _params) do
    account = conn.assigns[:current_account]
    changeset = Connection.changeset(%Connection{})
    render(conn, "new.html", changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
  end

  def create(conn, %{"connection" => connection_params}) do
    account = conn.assigns[:current_account]
    case Connection.create(%Connection{account_id: conn.assigns[:current_account].id}, connection_params) do
      {:ok, connection} ->
        case Connection.connect(connection) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Connection created successfully.")
            |> redirect(to: connection_path(conn, :index))
          {:error, results} ->
            IO.inspect(results)
            conn
            |> put_flash(:info, "Failed to create connection.")
            |> redirect(to: connection_path(conn, :index))
        end
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
    end
  end

  def show(conn, %{"id" => id}) do
    account = conn.assigns[:current_account]
    connection = Connection.get!(account, id)
    render(conn, "show.html", connection: connection)
  end

  def edit(conn, %{"id" => id}) do
    account = conn.assigns[:current_account]
    connection = Connection.get!(account, id)
    changeset = Connection.changeset(connection)
    render(conn, "edit.html", connection: connection, changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
  end

  def update(conn, %{"id" => id, "connection" => connection_params}) do
    account = conn.assigns[:current_account]
    connection = Connection.get!(account, id)
    changeset = Connection.changeset(connection, connection_params)

    case Connection.update(changeset) do
      {:ok, connection} ->
        conn
        |> put_flash(:info, "Connection updated successfully.")
        |> redirect(to: connection_path(conn, :show, connection))
      {:error, changeset} ->
        render(conn, "edit.html", connection: connection, changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
    end
  end

  def delete(conn, %{"id" => id}) do
    conn.assigns[:current_account]
    |> Connection.get!(id)
    |> Connection.disconnect!
    |> Connection.delete!

    conn
    |> put_flash(:info, "Connection deleted successfully.")
    |> redirect(to: connection_path(conn, :index))
  end
end
