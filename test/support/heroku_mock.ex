defmodule HerokuConnector.Heroku.AppsServiceMock do
  def list(_client) do
    []
  end

  def get(_client, app_id) do
    %Happi.Heroku.App{id: app_id, web_url: "somesite.herokuapp.com"}
  end
end

defmodule HerokuConnector.Heroku.DynoServiceMock do
  def list(_client) do
    []
  end
end

defmodule HerokuConnector.Heroku.DomainsServiceMock do
  def create(_client, _map) do
    %Happi.Heroku.Domain{id: "1"}
  end

  def delete(_client, id) do
    %Happi.Heroku.Domain{id: id}
  end
end

defmodule HerokuConnector.Heroku.AddonsServiceMock do
  def create(_client, _map) do
    %Happi.Heroku.Addon{}
  end

  def delete(_client, id) do
    %Happi.Heroku.Addon{id: id}
  end

  def get(_client, id) do
    %Happi.Heroku.Addon{id: id}
  end
end

defmodule HerokuConnector.Heroku.SslEndpointsServiceMock do
  def create(_client, _map) do
    %Happi.Heroku.SslEndpoint{}
  end

  def update(_client, id, _map) do
    %Happi.Heroku.SslEndpoint{id: id}
  end

  def delete(_client, id) do
    %Happi.Heroku.SslEndpoint{id: id}
  end
end
