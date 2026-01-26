defmodule Larabot.Webhook do
  alias Larabot.Error
  alias Nostrum.Api.Channel
  alias Nostrum.Api.Webhook
  alias Nostrum.Cache.Me

  def get_or_create(channel_id) do
    name = "Larabot"

    webhooks =
      channel_id
      |> Channel.webhooks()
      |> Error.handle()

    webhook = Enum.find(webhooks, &(&1.name == name && &1.user.id == Me.get().id))

    if webhook do
      webhook
    else
      channel_id
      |> Webhook.create(%{name: name, avatar: nil})
      |> Error.handle()
    end
  end
end
