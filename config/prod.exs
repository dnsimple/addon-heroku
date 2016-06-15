use Mix.Config

config :heroku_connector, HerokuConnector.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [scheme: "https", host: System.get_env("APP_HOSTNAME"), port: 443], force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/manifest.json",
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :logger, level: :info

config :heroku_connector, HerokuConnector.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true

config :heroku_connector,
  dnsimple_client_id: System.get_env("DNSIMPLE_CLIENT_ID"),
  dnsimple_client_secret: System.get_env("DNSIMPLE_CLIENT_SECRET"),
  heroku_client_id: System.get_env("HEROKU_CLIENT_ID"),
  heroku_client_secret: System.get_env("HEROKU_CLIENT_SECRET")
