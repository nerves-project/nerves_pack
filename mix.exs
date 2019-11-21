defmodule NervesPack.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_pack,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev, runtime: false},
      {:mdns_lite, "~> 0.2"},
      {:nerves_firmware_ssh, "~> 0.4"},
      {:nerves_runtime, "~> 0.6"},
      {:nerves_time, "~> 0.3"},
      {:ring_logger, "~> 0.8"},
      {:vintage_net, "~> 0.6"},
      {:vintage_net_wizard, "~> 0.1"}
    ]
  end
end
