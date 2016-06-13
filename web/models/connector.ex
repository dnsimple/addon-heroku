defmodule HerokuConnector.Connector do

  defmodule Configuration do
    use Ecto.Schema

    embedded_schema do
    end
  end

  use HerokuConnector.Web, :model

  alias HerokuConnector.Connector

  schema "connectors" do
    belongs_to :account, HerokuConnector.Account
    field :dnsimple_domain_id, :string
    field :heroku_app_id, :string
    embeds_one :configuration, HerokuConnector.Connector.Configuration, on_replace: :delete

    timestamps
  end

  @required_fields ~w(account_id dnsimple_domain_id heroku_app_id)
  @optional_fields ~w()

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
    Repo.get(Connector, id)
  end

  def get!(id) do
    Repo.get!(Connector, id)
  end

  def all do
    Repo.all(Connector)
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
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

  def delete!(model) do
    Repo.delete!(model)
  end
end
