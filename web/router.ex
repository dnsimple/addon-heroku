defmodule HerokuConnector.Router do
  use HerokuConnector.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HerokuConnector do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    get "/dnsimple/authorize", DnsimpleOauthController, :new
    get "/dnsimple/callback",  DnsimpleOauthController, :create

    get "/heroku/authorize", HerokuOauthController, :new
    get "/heroku/callback", HerokuOauthController, :create

    resources "/connections", ConnectionController
  end

  # Other scopes may use custom stacks.
  # scope "/api", HerokuConnector do
  #   pipe_through :api
  # end
end
