defmodule NervesPack.MixProject do
  use Mix.Project

  @source_url "https://github.com/nerves-project/nerves_pack"
  @version "0.3.0"

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
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NervesPack.Application, []}
    ]
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs]
    ]
  end

  defp deps do
    [
      {:mdns_lite, "~> 0.6"},
      {:nerves_firmware_ssh, "~> 0.4"},
      {:nerves_runtime, "~> 0.6"},
      {:nerves_time, "~> 0.3"},
      {:ring_logger, "~> 0.8"},
      {:vintage_net, "~> 0.7.0"},
      {:vintage_net_direct, "~> 0.7.0"},
      {:vintage_net_ethernet, "~> 0.7.0"},
      {:vintage_net_wifi, "~> 0.7.0"},

      # Dev Dependencies
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
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
