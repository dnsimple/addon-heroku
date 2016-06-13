defmodule HerokuConnector.Account do
  use HerokuConnector.Web, :model

  alias HerokuConnector.Account

  schema "accounts" do
    field :dnsimple_account_id, :string
    field :dnsimple_account_email, :string
    field :dnsimple_access_token, :string
    field :heroku_account_id, :string
    field :heroku_access_token, :string
    field :heroku_access_token_expires_at, Timex.Ecto.DateTime
    field :heroku_refresh_token, :string

    timestamps
  end

  @required_fields ~w(dnsimple_account_id)
  @optional_fields ~w(dnsimple_account_email dnsimple_access_token heroku_account_id heroku_access_token heroku_access_token_expires_at heroku_refresh_token)

  def create(model, params \\ %{}) do
    model
    |> changeset(params)
    |> Repo.insert
  end

  def create!(model, params \\ %{}) do
    model
    |> changeset(params)
    |> Repo.insert!
  end

  def get(id) do
    Repo.get(Account, id)
  end

  def get!(id) do
    Repo.get!(Account, id)
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

  def changeset(model, params \\ :invalid) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def update(changeset) do
    Repo.update(changeset)
  end

  def update!(changeset) do
    Repo.update!(changeset)
  end

  def delete(model) do
    Repo.delete(model)
  end
end
