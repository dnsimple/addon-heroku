defmodule HerokuConnector.WebhookRequestTracker do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: WebhookRequestTracker)
  end

  def handle(request_identifier, callback) do
    GenServer.call(WebhookRequestTracker, {:handle, request_identifier, callback})
  end

  # GenServer callbacks

  def init([]) do
    {:ok, %{}}
  end

  def handle_call({:handle, request_identifier, callback}, _from, request_identifiers) do
    request_identifiers = case Map.has_key?(request_identifiers, request_identifier) do
      true -> request_identifiers
      false ->
        callback.()
        Map.put(request_identifiers, request_identifier, true)
    end
    {:reply, :ok, request_identifiers}
  end
end
