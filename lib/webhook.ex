defmodule Larabot.Webhook do
  alias Larabot.Error
  alias Nostrum.Api.Channel
  alias Nostrum.Api.Webhook

  def get_or_create(channel_id) do
    webhooks =
      channel_id
      |> Channel.webhooks()
      |> Error.handle()

    webhook = Enum.find(webhooks, & &1.token)

    if webhook do
      webhook
    else
      channel_id
      |> Webhook.create(%{name: "Larabot", avatar: nil})
      |> Error.handle()
    end
  end
end
