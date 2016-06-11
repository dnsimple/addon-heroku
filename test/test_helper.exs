ExUnit.start

Mix.Task.run "ecto.create", ~w(-r HerokuConnector.Repo --quiet)
# Mix.Task.run "ecto.migrate", ~w(-r HerokuConnector.Repo --quiet)
Ecto.Adapters.SQL.Sandbox.mode(HerokuConnector.Repo, :manual)
