defmodule HerokuConnector.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :email, :string
      add :dnsimple_access_token, :string
      add :heroku_access_token, :string
      add :heroku_access_token_expires_at, :timestamp
      add :heroku_refresh_token, :string

      timestamps
    end
  end
end
