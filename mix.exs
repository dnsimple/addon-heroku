defmodule HerokuConnector.Mixfile do
  use Mix.Project

  def project do
    [app: :heroku_connector,
     version: "0.0.1",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {HerokuConnector, []},
     applications: [:phoenix, :phoenix_html, :cowboy, :logger, :gettext,
                    :phoenix_ecto, :postgrex, :dnsimple, :oauth2, :happi]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.0"},
     {:postgrex, "~> 0.11.2"},
     {:phoenix_ecto, "~> 3.0"},
     {:phoenix_html, "~> 2.6.2"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"},
     {:dnsimple, "~> 1.0"},
     {:happi, git: "https://github.com/aeden/happi.git", tag: "0.0.8"},
     {:oauth2, "~> 0.8"}]
  end

  # Aliases are shortcut or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"]]
  end
end
