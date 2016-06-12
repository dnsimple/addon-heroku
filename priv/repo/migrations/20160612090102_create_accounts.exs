defmodule HerokuConnector.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :dnsimple_account_id, :string
      add :dnsimple_account_email, :string
      add :dnsimple_access_token, :string

      add :heroku_account_id, :string
      add :heroku_access_token, :string
      add :heroku_access_token_expires_at, :timestamp
      add :heroku_refresh_token, :string

      timestamps
    end
    create index(:accounts, [:dnsimple_account_id])
    create index(:accounts, [:heroku_account_id])
  end
end
