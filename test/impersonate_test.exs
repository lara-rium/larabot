defmodule Larabot.ImpersonateTest do
  use ExUnit.Case, async: false
  use Nostrum.Consumer

  alias Larabot.Component
  alias Larabot.Error
  alias Nostrum.Api.Message

  @process :impersonate_test

  @message_options [
    content: "this message should be impersonated exactly the same way ",
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
    nonce: "impersonate test",
    tts: true,
    embeds: [
      %{
        description: "test embed 1"
      }
    ]
  ]

  def handle_event({:MESSAGE_CREATE, message, _}) do
    if message.nonce == @message_options[:nonce] do
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

    message_options =
      Keyword.merge(
        @message_options,
        [message_reference: %{message_id: referenced_message.id}] ++ message_options
      )

    channel_id
    |> Message.create(message_options)
    |> Error.handle!()

    assert_receive message

    message
    |> Larabot.Impersonate.impersonate(files_behavior: :clone)
    |> Error.handle!()

    opts = [files_behavior: :ignore, delete_original: true]

    new_message = %{
      message
      | content: message.content <> "\n```ex\n#{inspect(opts)}\n```"
    }

    new_message
    |> Larabot.Impersonate.impersonate(opts)
    |> Error.handle!()
  end

  setup do
    start_supervised!(__MODULE__)
    :ok
  end

  test "impersonate works with content, embeds and components" do
    test_impersonate(
      content: "this message should be impersonated exactly the same way *(except for reference)*"
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
        flags: Component.v2_flag(),
        content: nil,
        embeds: []
      )
    end
  end

  test "impersonate works with poll" do
    test_impersonate(
      poll: %{
        question: %{text: "impersonate poll question"},
        answers: [%{poll_media: %{text: "impersonate poll answer"}}]
      },
      files: []
    )
  end
end
