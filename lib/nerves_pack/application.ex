defmodule NervesPack.Application do
  @moduledoc false

  use Application
  require Logger

  alias VintageNet.Technology.{Ethernet, Gadget}

  def start(_type, _args) do
    configure_networking()

    children =
      [NervesPack.SSH]
      |> add_wifi_wizard_button()

    opts = [strategy: :one_for_one, name: NervesPack.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp add_wifi_wizard_button(children) do
    if Application.get_env(:nerves_pack, :wifi_wizard_button, true) do
      [NervesPack.WiFiWizardButton | children]
    else
      children
    end
  end

  defp configure_networking() do
    configured = VintageNet.configured_interfaces()

    all =
      VintageNet.all_interfaces()
      |> Enum.reject(&String.starts_with?(&1, "lo"))

    for ifname <- all, ifname not in configured do
      case ifname do
        "eth" <> _ ->
          VintageNet.configure(ifname, %{type: Ethernet})

        "usb" <> _ ->
          VintageNet.configure(ifname, %{type: Gadget})

        "wlan" <> _ ->
          VintageNetWizard.run_wizard()

          Logger.info("""
          [NervesPack] WiFi interface is available on wlan0, but not configured.
          For convenience, the WiFi Wizard has been started and networks can be
          setup via the web interface. To do so, connect to your device's network,
          then open a browser to one of the supported addresses to complete setup:

          * configured device hostname (i.e. http://nerves.local)
          * default device hostname (i.e. http://nerves-ac23.local)
          * http://wifi.config
          * http://192.168.0.1

          If your device supports USB Gadget, you can also skip joining its broadcasted
          network and use the device hostname in a browser to continue setup.

          For more info, see https://github.com/nerves-networking/vintage_net_wizard
          """)

        _ ->
          Logger.warn(
            "[NervesPack] No default interface configuration is available for #{ifname} - Skipping.."
          )
      end
    end
  end
end
