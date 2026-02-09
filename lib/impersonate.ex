require Protocol
Protocol.derive(Jason.Encoder, Nostrum.Struct.Message.Attachment)
Protocol.derive(Jason.Encoder, Nostrum.Struct.Message.Component)

# credo:disable-for-next-line Credo.Check.Refactor.ModuleDependencies
defmodule Larabot.Impersonate do
  alias Larabot.Error
  alias Nostrum.Api.Webhook
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.User

  def validate_components(components) do
    if Enum.any?(
         components,
         fn c ->
           c
           |> Map.from_struct()
           |> Map.drop([:type])
           |> Map.values()
           |> Enum.all?(&is_nil/1)
         end
       ), do: {:error, :components_v2_not_supported}, else: :ok
  end

  def validate_attachments(attachments) do
    if Enum.any?(attachments, &(&1.size > 10 * 1024 * 1024)),
      do: {:error, :attachment_too_large},
      else: :ok
  end

  def clone_files(attachments, message_id) do
    attachments
    |> Enum.with_index()
    |> Enum.map(fn {attachment, index} -> clone_file(index, attachment, message_id) end)
  end

  def clone_file(index, attachment, message_id) do
    dir = Path.join(System.tmp_dir!(), to_string(message_id))
    File.mkdir_p!(dir)
    path = Path.join(dir, attachment.filename)

    Req.get!(attachment.url, into: File.stream!(path), http_errors: :raise)

    {path, %{attachment | id: index, url: nil, proxy_url: nil}}
  end

  def prepend_reference(content, message_reference) do
    reference_link =
      "https://discord.com/channels/#{message_reference.guild_id}/#{message_reference.channel_id}/#{message_reference.message_id}"

    "-# *↪︎ #{reference_link}*\n#{content}"
  end

  # TODO: instead of a bool for clone_files allow passing of what to do if files exist: error, clone, or ignore
  def impersonate(message, clone_files \\ false) do
    with :ok <- validate_components(message.components),
         :ok <- if(clone_files, do: validate_attachments(message.attachments), else: :ok) do
      do_impersonate(message, clone_files)
    end
  end

  def do_impersonate(message, clone_files) do
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

    content =
      if message.referenced_message do
        prepend_reference(message.content, message.message_reference)
      else
        message.content
      end

    webhook.id
    |> Webhook.execute(
      webhook.token,
      %{
        attachments: attachments,
        components: message.components,
        # TODO: check message content below limit
        content: content,
        files: files,
        embeds: message.embeds,
        # TODO: test this for nick
        username: message.member.nick || message.author.username,
        # TODO: test this for guild avatar
        avatar_url: avatar_url,
        # TODO: test this
        tts: message.tts,
        flags: Map.get(message, :flags, 0),
        # TODO: test this
        allowed_mentions: Map.get(message, :allowed_mentions, :all),
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
