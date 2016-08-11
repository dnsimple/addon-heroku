use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :heroku_connector, HerokuConnector.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin"]]

# Watch static and templates for browser reloading.
config :heroku_connector, HerokuConnector.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :heroku_connector, HerokuConnector.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "heroku_connector_dev",
  hostname: "localhost",
  pool_size: 10

config :heroku_connector,
  dnsimple_client_id: "9e0621f55ad7aec6",
  dnsimple_client_secret: "oRnsTkiTK3J0t7lWuCb22gMpdhRdLLvX",
  heroku_client_id: "c0920219-7ef7-41f9-8645-d599db85b2a5",
  heroku_client_secret: "f77ed12c-7126-4acc-9513-9143ebeae4e5"

import_config "local.exs"
