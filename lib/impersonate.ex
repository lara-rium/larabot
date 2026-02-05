require Protocol
Protocol.derive(Jason.Encoder, Nostrum.Struct.Message.Attachment)
Protocol.derive(Jason.Encoder, Nostrum.Struct.Message.Component)

defmodule Larabot.Impersonate do
  alias Larabot.Error
  alias Nostrum.Api.Webhook
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.User

  def clone_files(attachments, message_id) do
    attachments
    |> Enum.with_index()
    |> Enum.map(fn {attachment, index} ->
      clone_file(index, attachment, message_id)
    end)
  end

  def clone_file(index, attachment, message_id) do
    # TODO: keep filename the same, it appears on client
    filename = to_string(message_id) <> attachment.filename

    temp_path =
      Path.join(
        System.tmp_dir!(),
        filename
      )

    Req.get!(attachment.url, into: File.stream!(temp_path), http_errors: :raise)

    {temp_path, %{attachment | id: index, filename: filename, url: nil, proxy_url: nil}}
  end

  def impersonate(message, clone_files \\ false) do
    webhook = Larabot.Webhook.get_or_create(message.channel_id)

    {files, attachments} =
      if clone_files,
        do:
          message.attachments
          |> clone_files(message.id)
          |> Enum.unzip(),
        else: {[], []}

    avatar_url =
      Member.avatar_url(message.member, message.guild_id) || User.avatar_url(message.author)

    # TODO: support message_reference

    webhook.id
    |> Webhook.execute(
      webhook.token,
      %{
        # TODO: check attachment size below limit
        attachments: attachments,
        # TODO: test components v2
        components: message.components,
        # TODO: check message content below limit
        content: message.content,
        files: files,
        embeds: message.embeds,
        # TODO: test this for nick
        username: message.member.nick || message.author.username,
        # TODO: test this for guild avatar
        avatar_url: avatar_url,
        # TODO: test this
        tts: message.tts,
        # TODO: test this
        flags: Map.get(message, :flags, 0),
        # TODO: test this
        allowed_mentions: Map.get(message, :allowed_mentions, nil),
        # TODO: test this
        poll: message.poll,
        # TODO: test this
        thread_name: message.thread && message.thread.name,
        # TODO: test this
        thread_tags: message.thread && message.thread.applied_tags
      }
    )
    |> Error.handle()
  end
end
