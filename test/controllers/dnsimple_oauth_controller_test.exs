defmodule HerokuConnector.DnsimpleOauthControllerTest do
  use HerokuConnector.ConnCase

  setup do
    {:ok, dnsimple_client_id: Application.fetch_env!(:heroku_connector, :dnsimple_client_id)}
  end

  test "/dnsimple/authorize", %{conn: conn, dnsimple_client_id: dnsimple_client_id} do
    conn = get conn, dnsimple_oauth_path(conn, :new)
    state = get_session(conn, :dnsimple_oauth_state)
    assert redirected_to(conn) == "https://dnsimple.com/oauth/authorize?response_type=code&client_id=#{dnsimple_client_id}&state=#{state}"
  end

  test "/dnsimple/callback", %{conn: conn} do
    conn = get conn, dnsimple_oauth_path(conn, :new)
    conn = get conn, dnsimple_oauth_path(conn, :create, state: get_session(conn, :dnsimple_oauth_state))
    assert html_response(conn, 200) =~ "Connected to DNSimple as"
  end

  test "/dnsimple/callback with mismatched state", %{conn: conn} do
    assert_raise(RuntimeError, fn() ->
      get conn, dnsimple_oauth_path(conn, :create, state: "bad")
    end)
  end

end
