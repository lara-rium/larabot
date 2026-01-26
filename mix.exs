defmodule Larabot.MixProject do
  use Mix.Project

  def project do
    [
      app: :larabot,
      version: "0.1.0",
      elixir: "~> 1.18",
      deps: deps()
    ]
  end

  def deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:exsync, "~> 0.4", only: :dev},
      {:nostrum, "~> 0.10"},
      {:req, "~> 0.5.0"}
    ]
  end
end
