defmodule HerokuConnector.Functions do
  def success_fn do
    fn(res) ->
      case res do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end
  end

  def non_nil_fn, do: &(&1 != nil)

  def extract_id_fn, do: fn({:ok, id}) -> id end
end
