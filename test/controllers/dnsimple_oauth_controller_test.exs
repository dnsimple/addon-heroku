defmodule HerokuConnector.DnsimpleOauthControllerTest do
  use HerokuConnector.ConnCase

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HerokuConnector.Repo)
    {:ok, dnsimple_client_id: Application.fetch_env!(:heroku_connector, :dnsimple_client_id)}
  end

  test "/dnsimple/authorize", %{dnsimple_client_id: dnsimple_client_id} do
    conn = get conn, dnsimple_oauth_path(conn, :new)
    state = get_session(conn, :dnsimple_oauth_state)
    assert redirected_to(conn) == "https://dnsimple.com/oauth/authorize?response_type=code&client_id=#{dnsimple_client_id}&state=#{state}"
  end

  test "/dnsimple/callback", %{dnsimple_client_id: _dnsimple_client_id} do
    conn = get conn, dnsimple_oauth_path(conn, :create)
    assert html_response(conn, 200) =~ "Connected to DNSimple as"
  end
end
