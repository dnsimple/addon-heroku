defmodule HerokuConnector.ConnectorController do
  use HerokuConnector.Web, :controller

  alias HerokuConnector.Connector

  plug HerokuConnector.Plug.CurrentAccount
  plug :scrub_params, "connector" when action in [:create, :update]

  def index(conn, _params) do
    account = conn.assigns[:current_account]
    connectors = Connector.all(account)
    render(conn, "index.html", connectors: connectors)
  end

  def new(conn, _params) do
    account = conn.assigns[:current_account]
    changeset = Connector.changeset(%Connector{})
    render(conn, "new.html", changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
  end

  def create(conn, %{"connector" => connector_params}) do
    account = conn.assigns[:current_account]
    case Connector.create(%Connector{account_id: conn.assigns[:current_account].id}, connector_params) do
      {:ok, _connector} ->
        conn
        |> put_flash(:info, "Connector created successfully.")
        |> redirect(to: connector_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
    end
  end

  def show(conn, %{"id" => id}) do
    account = conn.assigns[:current_account]
    connector = Connector.get!(account, id)
    render(conn, "show.html", connector: connector)
  end

  def edit(conn, %{"id" => id}) do
    account = conn.assigns[:current_account]
    connector = Connector.get!(account, id)
    changeset = Connector.changeset(connector)
    render(conn, "edit.html", connector: connector, changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
  end

  def update(conn, %{"id" => id, "connector" => connector_params}) do
    account = conn.assigns[:current_account]
    connector = Connector.get!(account, id)
    changeset = Connector.changeset(connector, connector_params)

    case Connector.update(changeset) do
      {:ok, connector} ->
        conn
        |> put_flash(:info, "Connector updated successfully.")
        |> redirect(to: connector_path(conn, :show, connector))
      {:error, changeset} ->
        render(conn, "edit.html", connector: connector, changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
    end
  end

  def delete(conn, %{"id" => id}) do
    conn.assigns[:current_account]
    |> Connector.get!(id)
    |> Connector.delete!

    conn
    |> put_flash(:info, "Connector deleted successfully.")
    |> redirect(to: connector_path(conn, :index))
  end
end
