use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :heroku_connector, HerokuConnector.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :heroku_connector, HerokuConnector.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "heroku_connector_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :heroku_connector,
  dnsimple_client_id: "dnsimple-client-id",
  dnsimple_client_secret: "dnsimple-client-secret",
  heroku_client_id: "heroku-client-id",
  heroku_client_secret: "heroku-client-secret",
  dnsimple_oauth_service: HerokuConnector.Dnsimple.OauthServiceMock,
  dnsimple_identity_service: HerokuConnector.Dnsimple.IdentityServiceMock,
  dnsimple_domains_service: HerokuConnector.Dnsimple.DomainsServiceMock,
  dnsimple_domain_services_service: HerokuConnector.Dnsimple.DomainServicesServiceMock,
  dnsimple_zones_service: HerokuConnector.Dnsimple.ZonesServiceMock,
  heroku_apps_service: HerokuConnector.Heroku.AppsServiceMock,
  heroku_domains_service: HerokuConnector.Heroku.DomainsServiceMock

