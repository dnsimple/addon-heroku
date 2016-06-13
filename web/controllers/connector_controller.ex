defmodule HerokuConnector.ConnectorController do
  use HerokuConnector.Web, :controller

  alias HerokuConnector.Connector

  plug HerokuConnector.Plug.CurrentAccount
  plug :scrub_params, "connector" when action in [:create, :update]

  def index(conn, _params) do
    connectors = Repo.all(Connector)
    render(conn, "index.html", connectors: connectors)
  end

  def new(conn, _params) do
    changeset = Connector.changeset(%Connector{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"connector" => connector_params}) do
    changeset = Connector.changeset(%Connector{account_id: conn.assigns[:current_account].id}, connector_params)

    case Repo.insert(changeset) do
      {:ok, _connector} ->
        conn
        |> put_flash(:info, "Connector created successfully.")
        |> redirect(to: connector_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    connector = Repo.get!(Connector, id)
    render(conn, "show.html", connector: connector)
  end

  def edit(conn, %{"id" => id}) do
    connector = Repo.get!(Connector, id)
    changeset = Connector.changeset(connector)
    render(conn, "edit.html", connector: connector, changeset: changeset)
  end

  def update(conn, %{"id" => id, "connector" => connector_params}) do
    connector = Repo.get!(Connector, id)
    changeset = Connector.changeset(connector, connector_params)

    case Repo.update(changeset) do
      {:ok, connector} ->
        conn
        |> put_flash(:info, "Connector updated successfully.")
        |> redirect(to: connector_path(conn, :show, connector))
      {:error, changeset} ->
        render(conn, "edit.html", connector: connector, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    connector = Repo.get!(Connector, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(connector)

    conn
    |> put_flash(:info, "Connector deleted successfully.")
    |> redirect(to: connector_path(conn, :index))
  end
end
