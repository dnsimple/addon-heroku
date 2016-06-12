defmodule HerokuConnector.Account do
  use HerokuConnector.Web, :model

  alias HerokuConnector.Account

  schema "accounts" do
    field :dnsimple_account_id, :string
    field :dnsimple_account_email, :string
    field :dnsimple_access_token, :string
    field :heroku_account_id, :string
    field :heroku_access_token, :string
    field :heroku_access_token_expires_at, Ecto.DateTime
    field :heroku_refresh_token, :string

    timestamps
  end

  @required_fields ~w(dnsimple_account_id)
  @optional_fields ~w(dnsimple_account_email dnsimple_access_token heroku_account_id heroku_access_token heroku_access_token_expires_at heroku_refresh_token)

  def create(account, params \\ %{}) do
    account
    |> changeset(params)
    |> Repo.insert
  end

  def create!(account, params \\ %{}) do
    account
    |> changeset(params)
    |> Repo.insert!
  end

  def find_or_create(dnsimple_account_id, params \\ %{}) do
    case Repo.get_by(Account, dnsimple_account_id: dnsimple_account_id) do
      nil -> create(%Account{dnsimple_account_id: dnsimple_account_id}, params)
      account -> {:ok, account}
    end
  end

  def find_or_create!(dnsimple_account_id, params \\ %{}) do
    case Repo.get_by(Account, dnsimple_account_id: dnsimple_account_id) do
      nil -> create!(%Account{dnsimple_account_id: dnsimple_account_id}, params)
      account -> account
    end
  end

  def changeset(account, params \\ :invalid) do
    account
    |> cast(params, @required_fields, @optional_fields)
  end

  def update(changeset) do
    Repo.update(changeset)
  end

  def update!(changeset) do
    Repo.update!(changeset)
  end

  def delete(account) do
    Repo.delete(account)
  end
end
