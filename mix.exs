defmodule NervesPack.MixProject do
  use Mix.Project

  @source_url "https://github.com/nerves-project/nerves_pack"
  @version "0.7.0"

  def project do
    [
      app: :nerves_pack,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
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

  defp deps do
    [
      {:nerves_ssh, "~> 0.3"},
      {:nerves_runtime, "~> 0.6"},
      {:nerves_time, "~> 0.3"},
      {:nerves_motd, "~> 0.1"},
      {:ring_logger, "~> 0.8"},
      {:vintage_net, "~> 0.10"},
      {:vintage_net_direct, "~> 0.10"},
      {:vintage_net_ethernet, "~> 0.10"},
      {:vintage_net_wifi, "~> 0.10"},
      {:mdns_lite, "~> 0.8"},

      # Dev dependencies
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
