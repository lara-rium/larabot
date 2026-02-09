defmodule Larabot.Error do
  require Logger

  def message(err, message) do
    err_msg = inspect(err, pretty: true)

    if message do
      "#{message}: #{err_msg}"
    else
      err_msg
    end
  end

  def handle(result, message \\ nil)

  def handle({:error, err}, message) do
    err
    |> message(message)
    |> Logger.error()

    {:error, err}
  end

  def handle({:ok, value}, _), do: value

  def handle(value, _), do: value

  def handle!(result, message \\ nil, exception \\ RuntimeError)

  def handle!({:error, err}, message, exception) do
    raise exception, message(err, message)
  end

  def handle!({:ok, value}, _, _), do: value

  def handle!(value, _, _), do: value

  def fallback({:error, err}, fun) do
    fun.(err)
  end

  def fallback(value, _), do: value
end
