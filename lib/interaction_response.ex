defmodule Larabot.InteractionResponse do
  alias Larabot.Component

  def channel_message_with_source(components) do
    %{
      type: 4,
      data: %{
        flags: Component.v2_flag(),
        components: components
      }
    }
  end
end
