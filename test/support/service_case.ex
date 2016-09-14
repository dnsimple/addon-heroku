defmodule HerokuConnector.ServiceCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use HerokuConnector.ConnCase
      alias HerokuConnector.Repo
      import HerokuConnector.ServiceCase
    end
  end
end
