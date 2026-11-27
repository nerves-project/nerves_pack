defmodule NervesPack.MixProject do
  use Mix.Project

  @source_url "https://github.com/nerves-project/nerves_pack"
  @version "0.7.2"

  def project do
    [
      app: :nerves_pack,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: "Common dependencies for Nerves devices",
      package: package(),
      aliases: aliases(),
      test_ignore_filters: [&String.starts_with?(&1, "test/fixtures/")],
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

  # nerves_pack's dependencies manage networking, the system clock and an SSH
  # server. They must not be started on the computer that runs the tests.
  defp aliases do
    [test: "test --no-start"]
  end

  defp deps do
    [
      # TODO(igniter): revert these to `"> 0.0.0"` once the versions with the
      # Igniter installers (and vintage_net with VintageNet.Generator) are
      # released. They point at the sibling checkouts for local development.
      {:nerves_ssh, path: "../nerves_ssh", override: true},
      {:nerves_runtime, path: "../nerves_runtime", override: true},
      {:nerves_time, path: "../nerves_time", override: true},
      {:nerves_motd, path: "../nerves_motd", override: true},
      {:ring_logger, path: "../ring_logger", override: true},
      {:vintage_net, path: "../vintage_net", override: true},
      {:vintage_net_direct, path: "../vintage_net_direct", override: true},
      {:vintage_net_ethernet, path: "../vintage_net_ethernet", override: true},
      {:vintage_net_wifi, path: "../vintage_net_wifi", override: true},
      {:mdns_lite, path: "../mdns_lite", override: true},
      {:igniter, "~> 0.6", optional: true, runtime: false},

      # Dev dependencies
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},

      # Test dependencies
      # TODO(igniter): revert to the Hex requirements once nerves and toolshed
      # with Igniter installers are released (`"~> 2.0"` and `"~> 0.5"`). These
      # are only used to test `mix nerves_pack.install` against the project
      # that `mix nerves.install` creates.
      {:nerves, path: "../nerves", only: :test, runtime: false},
      {:toolshed, path: "../toolshed", only: :test, runtime: false}
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
        "LICENSES/*",
        "mix.exs",
        "README.md",
        "REUSE.toml"
      ],
      licenses: ["CC0-1.0"],
      links: %{
        "GitHub" => @source_url,
        "REUSE Compliance" =>
          "https://api.reuse.software/info/github.com/nerves-project/nerves_pack"
      }
    }
  end
end
