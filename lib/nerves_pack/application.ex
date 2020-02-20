defmodule NervesPack.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    _ = configure_networking()
    _ = configure_mdns()

    ssh_port = Application.get_env(:nerves_pack, :ssh_port, 22)

    children = [{NervesPack.SSH, %{ssh_port: ssh_port}}]

    opts = [strategy: :one_for_one, name: NervesPack.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp configure_mdns() do
    # For convenience, we'll allow specifying host and services
    # in :mdns_lite or :nerves_pack scopes
    mdns_config = Application.get_all_env(:mdns_lite)
    nerves_pack_config = Application.get_all_env(:nerves_pack)

    # If mdns_config has services, then no need to configure
    # more. Otherwise, look for :nerves_pack services or use defaults
    unless mdns_config[:services] do
      default_services = [
        %{
          name: "SSH Remote Login Protocol",
          protocol: "ssh",
          transport: "tcp",
          port: 22
        },
        %{
          name: "Secure File Transfer Protocol over SSH",
          protocol: "sftp-ssh",
          transport: "tcp",
          port: 22
        },
        %{
          name: "Erlang Port Mapper Daemon",
          protocol: "epmd",
          transport: "tcp",
          port: 4369
        }
      ]

      Keyword.get(nerves_pack_config, :services, default_services)
      |> MdnsLite.add_mdns_services()
    end

    # If the mdns_config has a host, then it has been set
    # and we don't need to do anything. Otherwise, use
    # :nerves_pack config or default
    unless mdns_config[:host] do
      Keyword.get(nerves_pack_config, :host, [:hostname, "nerves"])
      |> MdnsLite.set_host()
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
          VintageNet.configure(ifname, %{type: VintageNetEthernet})

        "usb" <> _ ->
          VintageNet.configure(ifname, %{type: VintageNetDirect})

        _ ->
          Logger.warn(
            "[NervesPack] No default interface configuration is available for #{ifname} - Skipping.."
          )
      end
    end
  end
end
