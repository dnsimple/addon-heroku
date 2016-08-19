defmodule HerokuConnector.ConnectionController do
  use HerokuConnector.Web, :controller
  require Logger

  alias HerokuConnector.Connection
  alias HerokuConnector.ConnectionService

  plug HerokuConnector.Plug.CurrentAccount
  plug :scrub_params, "connection" when action in [:create, :update]

  def index(conn, _params) do
    account = conn.assigns[:current_account]
    case Connection.all(account) do
      [] ->
        conn
        |> put_flash(:info, "You have no connections; go ahead and create one.")
        |> redirect(to: connection_path(conn, :new))
      connections ->
        render(conn, "index.html", connections: connections)
    end
  end

  def new(conn, _params) do
    account = conn.assigns[:current_account]
    changeset = Connection.changeset(%Connection{})
    render(conn, "new.html", changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
  end

  def create(conn, %{"connection" => connection_params}) do
    account = conn.assigns[:current_account]
    case Connection.create(%Connection{account_id: account.id}, connection_params) do
      {:ok, connection} ->
        case HerokuConnector.Dnsimple.certificates(account, connection.dnsimple_domain_id) do
          [] ->
            connect(conn, %{"id" => connection.id, "connection" => %{"id" => 0}})
          _ ->
            redirect(conn, to: connection_path(conn, :connect, connection))
        end
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
    end
  end

  def connect(conn, %{"id" => id, "connection" => connection_params}) do
    account = conn.assigns[:current_account]
    connection = Connection.get!(account, id) |> Repo.preload(:account)
    case ConnectionService.connect(connection, connection_params) do
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
  end

  def connect(conn, %{"id" => id}) do
    account = conn.assigns[:current_account]
    connection = Connection.get!(account, id)
    case HerokuConnector.Dnsimple.active_certificates(account, connection.dnsimple_domain_id) do
      [] ->
        connect(conn, %{"id" => connection.id, "connection" => %{"id" => 0}})
      certificates ->
        domain = HerokuConnector.Dnsimple.domain(account, connection.dnsimple_domain_id)
        changeset = Connection.changeset(connection)
        render(conn, "connect.html", changeset: changeset, connection: connection, dnsimple_domain: domain, dnsimple_certificates: certificates)
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
    case HerokuConnector.Dnsimple.certificates(account, connection.dnsimple_domain_id) do
      [] ->
        reconnect(conn, %{"id" => connection.id, "connection" => connection_params})
      _ ->
        redirect(conn, to: connection_path(conn, :reconnect, connection, %{"connection" => connection_params}))
    end
  end

  def reconnect(conn, %{"id" => id, "connection" => connection_params}) do
    account = conn.assigns[:current_account]
    connection = Connection.get!(account, id)
    changeset = Connection.changeset(connection, connection_params)

    # First get the domain (new or old) to check for the certificate
    model = changeset.data |> Repo.preload(:account)
    domain = HerokuConnector.Dnsimple.domain(model.account, model.dnsimple_domain_id)
    new_domain = case Map.get(changeset.changes, :dnsimple_domain_id) do
      nil -> domain
      dnsimple_domain_id ->  HerokuConnector.Dnsimple.domain(model.account, dnsimple_domain_id)
    end

    # Check if there are any certificates present on the target domain
    case HerokuConnector.Dnsimple.active_certificates(account, new_domain.id) do
      [] ->
        # No certificates on the target domain, reconnect immediately
        case ConnectionService.reconnect(changeset) do
          {:ok, _} ->
            case Connection.update(changeset) do
              {:ok, new_connection} ->
                conn
                |> put_flash(:info, "Connection updated successfully.")
                |> redirect(to: connection_path(conn, :show, new_connection))
              {:error, changeset} ->
                render(conn, "edit.html", connection: connection, changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
            end
          {:error, _} ->
            render(conn, "edit.html", connection: connection, changeset: changeset, dnsimple_domains: HerokuConnector.Dnsimple.domains(account), heroku_apps: HerokuConnector.Heroku.apps(account))
        end
      certificates ->
        case Map.get(connection_params, "dnsimple_certificate_id") do
          nil ->
            # Certificates on the target domain and no certificate id passed
            render(conn, "reconnect.html", changeset: changeset, connection: connection, dnsimple_domain: new_domain, dnsimple_certificates: certificates)
          _certificate_id ->
            # Certificates on the target domain and certificate id passed
            case ConnectionService.reconnect(changeset, connection_params) do
              {:ok, _} ->
                case Connection.update(changeset) do
                  {:ok, new_connection} ->
                    conn
                    |> put_flash(:info, "Connection updated successfully.")
                    |> redirect(to: connection_path(conn, :show, new_connection))
                  {:error, changeset} ->
                    render(conn, "reconnect.html", changeset: changeset, connection: connection, dnsimple_domain: new_domain, dnsimple_certificates: certificates)
                end
              {:error, _} ->
                render(conn, "reconnect.html", changeset: changeset, connection: connection, dnsimple_domain: new_domain, dnsimple_certificates: certificates)
            end
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    conn.assigns[:current_account]
    |> Connection.get!(id)
    |> ConnectionService.disconnect!
    |> Connection.delete!

    conn
    |> put_flash(:info, "Connection deleted successfully.")
    |> redirect(to: connection_path(conn, :index))
  end
end
