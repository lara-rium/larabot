defmodule Larabot.Webhook do
  alias Larabot.Error
  alias Nostrum.Api.Channel
  alias Nostrum.Api.Webhook

  def get_or_create(channel_id) do
    do_get_or_create(channel_id)
  end

  defp do_get_or_create(channel_id, thread_id \\ nil) do
    case Channel.webhooks(channel_id) do
      {:ok, webhooks} ->
        {Enum.find(webhooks, & &1.token) ||
           channel_id
           |> Webhook.create(%{name: "Larabot", avatar: nil})
           |> Error.handle(), %{thread_id: thread_id}}

      {:error, err} ->
        if !thread_id && err.response.code == 10_003 do
          thread =
            channel_id
            |> Channel.get()
            |> Error.handle()

          do_get_or_create(thread.parent_id, thread.id)
        end
    end
  end
end
