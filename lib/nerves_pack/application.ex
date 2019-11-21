defmodule NervesPack.Application do
  @moduledoc false

  use Application
  require Logger

  alias VintageNet.Technology.{Ethernet, Gadget, WiFi}

  def start(_type, _args) do
    configure_networking()

    children = [
      NervesPack.SSH
    ]

    opts = [strategy: :one_for_one, name: NervesPack.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp configure_networking() do
    configured = VintageNet.configured_interfaces()
    all = VintageNet.all_interfaces() |> Enum.reject(&String.starts_with?(&1, "lo"))

    for ifname <- all, ifname not in configured do
      if type = type_for_ifname(ifname) do
        VintageNet.configure(ifname, %{type: type})
      else
        Logger.warn("[NervesPack] unsupported default network interface: #{ifname}")
      end
    end
  end

  defp type_for_ifname("eth" <> _), do: Ethernet
  defp type_for_ifname("usb" <> _), do: Gadget
  defp type_for_ifname("wlan" <> _), do: WiFi
  defp type_for_ifname(_), do: nil
end
