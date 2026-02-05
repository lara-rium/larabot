import Config

config :nostrum,
  ffmpeg: nil,
  log_full_events: true,
  log_dispatch_events: false,
  gateway_intents: [:guild_messages]

config :logger, :console,
  level: :debug,
  metadata: [:shard, :guild, :channel]
