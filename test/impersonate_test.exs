defmodule Larabot.ImpersonateTest do
  use ExUnit.Case
  use Nostrum.Consumer
  alias Larabot.Error

  @nonce "impersonate test"
  @process :impersonate_test

  def handle_event({:MESSAGE_CREATE, message, _}) do
    if message.nonce == @nonce do
      send(@process, message)
    end
  end

  setup do
    start_supervised!(__MODULE__)
    :ok
  end

  test "impersonate works" do
    Process.register(self(), @process)

    channel_id = Application.fetch_env!(:larabot, :channel_id)

    referenced_message =
      Nostrum.Api.Message.create(channel_id,
        content: "reference message for impersonation test"
      )
      |> Error.handle()

    Nostrum.Api.Message.create(channel_id,
      content: "this message should be impersonated exactly the same way",
      files: [
        %{
          name: "file1.txt",
          body: "test file 1\n"
        },
        %{
          name: "file2.txt",
          body: "test file 2\n"
        }
      ],
      embeds: [
        %{
          description: "test embed 1"
        }
      ],
      components: [
        %{
          type: 1,
          components: [
            %{
              type: 2,
              style: 5,
              label: "Test Button",
              url: "https://lara.lv"
            }
          ]
        }
      ],
      message_reference: %{message_id: referenced_message.id},
      nonce: @nonce
    )
    |> Error.handle()

    assert_receive message

    Larabot.Impersonate.impersonate(message, true) |> Error.handle()

    new_message = %{message | content: message.content <> "\n*clone files set to false*"}
    Larabot.Impersonate.impersonate(new_message) |> Error.handle()
  end
end
