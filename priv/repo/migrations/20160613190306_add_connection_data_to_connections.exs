defmodule HerokuConnector.Repo.Migrations.AddConnectionDataToConnections do
  use Ecto.Migration

  def change do
    alter table(:connections) do
      add :connection_data, :map
    end
  end
end
