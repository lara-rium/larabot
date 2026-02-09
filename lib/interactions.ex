defmodule Larabot.Interactions do
  @callback commands() :: any()

  defmacro __using__(_) do
    quote do
      alias Larabot.Error
      alias Nostrum.Api.ApplicationCommand

      @app Mix.Project.config()[:app]

      @behaviour Larabot.Interactions

      def command_ids do
        Application.get_env(@app, :command_ids, %{})
      end

      def register do
        guild_id = Application.get_env(@app, :guild_id)
        commands = Enum.map(commands(), &1.command())

        if guild_id do
          guild_id
          |> ApplicationCommand.bulk_overwrite_guild_commands(commands)
          |> Error.handle()
        end

        {:ok, commands_response} =
          commands
          |> ApplicationCommand.bulk_overwrite_global_commands()
          |> Error.handle()

        command_ids = Map.new(commands_response, &{&1.name, &1.id})

        Application.put_env(@app, :command_ids, command_ids)
      end

      def handle(interaction) do
        command =
          Enum.find(commands(), &1.name() == interaction.data.name)

        command.handle(interaction)
      end
    end
  end
end
