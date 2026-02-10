defmodule Larabot.ImpersonateTest do
  use ExUnit.Case, async: false
  use Nostrum.Consumer

  alias Larabot.Component
  alias Larabot.Error
  alias Nostrum.Api.Message

  @nonce "impersonate test"
  @process :impersonate_test

  def handle_event({:MESSAGE_CREATE, message, _}) do
    if message.nonce == @nonce do
      send(@process, message)
    end
  end

  def test_impersonate(message_options) do
    Process.register(self(), @process)

    channel_id = Application.fetch_env!(:larabot, :channel_id)

    referenced_message =
      channel_id
      |> Message.create("reference message for impersonation test")
      |> Error.handle!()

    channel_id
    |> Message.create(
      message_options ++
        [
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
          message_reference: %{message_id: referenced_message.id},
          nonce: @nonce
        ]
    )
    |> Error.handle!()

    assert_receive message

    message
    |> Larabot.Impersonate.impersonate(files_behavior: :clone)
    |> Error.handle!()

    new_message = %{message | content: message.content <> "\n*(clone files set to ignore)*"}

    new_message
    |> Larabot.Impersonate.impersonate(files_behavior: :ignore)
    |> Error.handle!()
  end

  setup do
    start_supervised!(__MODULE__)
    :ok
  end

  test "impersonate works" do
    test_impersonate(
      content:
        "this message should be impersonated exactly the same way *(except for reference)*",
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
      ]
    )
  end

  test "impersonate errors with components v2" do
    assert_raise RuntimeError, ":components_v2_not_supported", fn ->
      test_impersonate(
        components: [
          Component.text("this message can't be impersonated because it has components v2"),
          Component.file("file1.txt"),
          Component.file("file2.txt")
        ],
        flags: Component.v2_flag()
      )
    end
  end
end
