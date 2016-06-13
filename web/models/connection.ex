defmodule HerokuConnector.Connection do

  defmodule Configuration do
    use Ecto.Schema

    embedded_schema do
    end
  end

  use HerokuConnector.Web, :model
  import Ecto.Query, only: [from: 2]

  alias HerokuConnector.Connection

  schema "connections" do
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

  def get(account, id) do
    query = from c in Connection, where: c.account_id == ^account.id
    Repo.get(query, id)
  end

  def get!(account, id) do
    query = from c in Connection, where: c.account_id == ^account.id
    Repo.get!(query, id)
  end

  def all(account) do
    query = from c in Connection, where: c.account_id == ^account.id
    Repo.all(query)
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

  @doc """
  Execute the connection at DNSimple and Heroku.
  """
  def connect(model) do
    model = Repo.preload(model, :account)

    domain = HerokuConnector.Dnsimple.domain(model.account, model.dnsimple_domain_id)
    app = HerokuConnector.Heroku.app(model.account, model.heroku_app_id)
    uri = URI.parse(app.web_url)

    records = IO.inspect [
      %Dnsimple.Record{type: "ALIAS", name: "", content: uri.host, ttl: 3600},
      %Dnsimple.Record{type: "CNAME", name: "www", content: uri.host, ttl: 3600}
    ]

    IO.inspect(HerokuConnector.Dnsimple.create_records(model.account, domain.name, records))

    {:ok, model}
  end
end
