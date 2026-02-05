defmodule Larabot.Error do
  require Logger

  def handle(result, message \\ nil)

  def handle({:error, err}, message) do
    err_msg = inspect(err, pretty: true)

    if message do
      Logger.error("#{message}: #{err_msg}")
    else
      Logger.error(err_msg)
    end

    {:error, err}
  end

  def handle({:ok, value}, _), do: value

  def handle(value, _), do: value
end
