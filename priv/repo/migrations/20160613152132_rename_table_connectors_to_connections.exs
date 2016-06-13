defmodule HerokuConnector.Repo.Migrations.RenameTableConnectorsToConnections do
  use Ecto.Migration

  def change do
    rename table(:connectors), to: table(:connections)
  end
end
