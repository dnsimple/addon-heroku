defmodule HerokuConnector.Heroku.AppsServiceMock do
  def list(_client) do
    []
  end

  def get(_client, app_id) do
    %Happi.Heroku.App{id: app_id, web_url: "somesite.herokuapp.com"}
  end
end
