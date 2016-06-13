defmodule HerokuConnector.Repo.Migrations.CreateConnector do
  use Ecto.Migration

  def change do
    create table(:connectors) do
      add :account_id, references(:accounts)
      add :dnsimple_domain_id, :string
      add :heroku_app_id, :string
      add :configuration, :map

      timestamps
    end

  end
end
