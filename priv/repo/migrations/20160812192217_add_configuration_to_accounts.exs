defmodule HerokuConnector.Repo.Migrations.AddConfigurationToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :configuration, :map
    end
  end
end
