defmodule HerokuConnector.GatewayCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias HerokuConnector.Repo
      import HerokuConnector.ServiceCase
    end
  end
end

