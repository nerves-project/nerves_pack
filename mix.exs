defmodule NervesPack.MixProject do
  use Mix.Project

  @source_url "https://github.com/nerves-project/nerves_pack"
  @version "0.2.2"

  def project do
    [
      app: :nerves_pack,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      xref: [exclude: [Circuits.GPIO, VintageNetWizard]],
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
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs],
      plt_add_apps: [:circuits_gpio, :vintage_net_wizard]
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
      # Optional Dependencies
      # Include vintage_net_wizard to use AP configuration.
      {:vintage_net_wizard, "~> 0.2.1", optional: true},
      # Include circuits_gpio to use wifi_wizard_button.
      {:circuits_gpio, "~> 0.4", optional: true},
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
