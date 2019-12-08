defmodule NervesPack.MixProject do
  use Mix.Project

  @source_url "https://github.com/jjcarstens/nerves_pack"
  @version "0.1.1"

  def project do
    [
      app: :nerves_pack,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
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

  defp deps do
    [
      {:busybox, "~> 0.1"},
      {:circuits_gpio, "~> 0.4"},
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev, runtime: false},
      {:mdns_lite, "~> 0.6"},
      {:nerves_firmware_ssh, "~> 0.4"},
      {:nerves_runtime, "~> 0.6"},
      {:nerves_time, "~> 0.3"},
      {:ring_logger, "~> 0.8"},
      {:vintage_net, "~> 0.7.0"},
      {:vintage_net_direct, "~> 0.7.0"},
      {:vintage_net_ethernet, "~> 0.7.0"},
      {:vintage_net_wifi, "~> 0.7.0"},
      {:vintage_net_wizard, "~> 0.2.0"}
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
