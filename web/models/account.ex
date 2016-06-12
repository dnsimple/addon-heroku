defmodule HerokuConnector.Account do
  use HerokuConnector.Web, :model

  schema "accounts" do
    field :email, :string
    field :dnsimple_access_token, :string
    field :heroku_access_token, :string
    field :heroku_access_token_expires_at, Ecto.DateTime
    field :heroku_refresh_token, :string

    timestamps
  end

  @required_fields ~w(email)
  @optional_fields ~w(dnsimple_access_token heroku_access_token heroku_access_token_expires_at heroku_refresh_token)

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
