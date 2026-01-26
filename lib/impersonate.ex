defmodule Larabot.Impersonate do
  alias Larabot.Error
  alias Nostrum.Api.Webhook
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.User

  def clone_files(attachments) do
    {
      Enum.map(attachments, &clone_file/1),
      Enum.map(attachments, &%{filename: &1.filename, description: &1.description})
    }
  end

  def clone_file(attachment) do
    temp_path = Path.join([System.tmp_dir!(), :erlang.unique_integer(), attachment.filename])

    Req.get!(attachment.url, into: File.stream!(temp_path), http_errors: :raise)

    temp_path
  end

  def impersonate(message, clone_files \\ false) do
    webhook = Larabot.Webhook.get_or_create(message.channel_id)

    {files, attachments} = if clone_files, do: clone_files(message.attachments), else: []

    avatar_url =
      Member.avatar_url(message.member, message.guild_id) || User.avatar_url(message.author)

    webhook.id
    |> Webhook.execute(webhook.token, %{
      attachments: attachments,
      components: message.components,
      content: message.content,
      files: files,
      embeds: message.embeds,
      username: message.member.nick || message.author.username,
      avatar_url: avatar_url,
      tts: message.tts,
      flags: message.flags,
      allowed_mentions: message.allowed_mentions,
      poll: message.poll,
      thread_name: message.thread.name,
      thread_tags: message.thread.applied_tags
    })
    |> Error.handle()
  end
end
