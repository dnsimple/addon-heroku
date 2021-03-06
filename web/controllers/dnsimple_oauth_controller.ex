defmodule HerokuConnector.DnsimpleOauthController do
  use HerokuConnector.Web, :controller

  alias HerokuConnector.Account

  def new(conn, _params) do
    client    = %Dnsimple.Client{}
    client_id = Application.fetch_env!(:heroku_connector, :dnsimple_client_id)
    state = :crypto.strong_rand_bytes(8) |> Base.url_encode64 |> binary_part(0, 8)
    conn = put_session(conn, :dnsimple_oauth_state, state)
    oauth_url = HerokuConnector.Dnsimple.authorize_url(client, client_id, state: state)
    redirect(conn, external: oauth_url)
  end

  def create(conn, params) do
    if params["state"] != get_session(conn, :dnsimple_oauth_state) do
      raise "State does not match"
    end

    client = %Dnsimple.Client{}
    attributes = %{
      client_id: Application.fetch_env!(:heroku_connector, :dnsimple_client_id),
      client_secret: Application.fetch_env!(:heroku_connector, :dnsimple_client_secret),
      code: params["code"],
      state: params["state"]
    }
    case HerokuConnector.Dnsimple.exchange_authorization_for_token(client, attributes) do
      {:ok, response} ->
        access_token = response.data.access_token
        client = %Dnsimple.Client{access_token: access_token}
        case HerokuConnector.Dnsimple.whoami(client) do
          {:ok, %Dnsimple.Response{data: data}} ->
            account = Account.find_or_create!(Integer.to_string(data.account.id), %{
              "dnsimple_account_email" => data.account.email,
              "dnsimple_access_token" => access_token
            })

            # Add a webhook if necessary
            require Logger
            url = case Mix.env do
              :dev ->
                Logger.debug("Using dev environment")
                Application.get_env(:heroku_connector, :webhook_url)
              env ->
                Logger.debug("Using environment #{inspect env}")
                webhook_url(conn, :handle, account.id)
            end
            Logger.debug("Creating webhook with url: #{url}")
            webhook = HerokuConnector.Dnsimple.create_webhook(account, url)
            Logger.debug("Webhook: #{inspect webhook}")

            account = case Account.update(Account.changeset(account, %{configuration: %{webhook_id: webhook.id}})) do
              {:ok, account} -> account
              {:error, error} ->
                IO.inspect(error)
                raise "Failed to update account with webhook ID: #{inspect error}"
            end

            conn
            |> put_session(:account_id, account.id)
            |> redirect(to: connection_path(conn, :index))
          {:error, error} ->
            IO.inspect(error)
            raise "Failed to retreive account details: #{inspect error}"
        end
      {:error, error} ->
        IO.inspect(error)
        raise "OAuth authentication failed: #{inspect error}"
    end
  end

end
