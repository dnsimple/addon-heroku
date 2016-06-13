defmodule HerokuConnector.ConnectionView do
  use HerokuConnector.Web, :view

  def domain_select_options(dnsimple_domains), do: Enum.map(dnsimple_domains, &({&1.name, &1.name}))

  def app_select_options(heroku_apps), do: Enum.map(heroku_apps, &({&1.name, &1.id}))
end
