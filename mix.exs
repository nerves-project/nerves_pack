defmodule NervesPack.MixProject do
  use Mix.Project

  @source_url "https://github.com/nerves-project/nerves_pack"
  @version "0.4.1"

  def project do
    [
      app: :nerves_pack,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      dialyzer: dialyzer(),
      deps: deps(),
      docs: docs(),
      description: "Initialization setup for Nerves devices",
      package: package(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.build": :docs,
        "hex.publish": :docs
      }
    ]
  end

  def application do
    []
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs]
    ]
  end

  defp deps do
    [
      {:nerves_ssh, "~> 0.2"},
      {:nerves_runtime, "~> 0.6"},
      {:nerves_time, "~> 0.3"},
      {:ring_logger, "~> 0.8"},
      {:vintage_net, "~> 0.7.0 or ~> 0.8.0 or ~> 0.9.0 or ~> 0.10.0"},
      {:vintage_net_direct, "~> 0.7"},
      {:vintage_net_ethernet, "~> 0.7"},
      {:vintage_net_wifi, "~> 0.7"},

      # :mdns_lite has an optional dependency on :vintage_net. Optional
      # dependencies are ignored by `mix` when making OTP releases. See
      # https://github.com/erlang/otp/pull/2675 for a fix. Until then, moving
      # it last in the list seems to help.
      {:mdns_lite, "~> 0.6"},

      # Dev dependencies
      {:dialyxir, "~> 1.1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package do
    %{
      files: [
        "CHANGELOG.md",
        "lib",
        "LICENSE",
        "mix.exs",
        "README.md"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end
end
