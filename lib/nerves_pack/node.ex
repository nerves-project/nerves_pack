defmodule NervesPack.Node do
  @type node_name :: atom() | charlist() | binary()
  @type node_host :: :dhcp | :hostname | :ip | :mdns | binary()

  @type node_return :: {:ok, pid()} | {:error, term()}

  defdelegate stop(), to: Node

  @doc """
  Start as a distributed node.

  Requires a valid node as the argument. i.e. `:"howdy@nerves.local"` or
  specifying the name for the node

  ```elixir
  start("howdy", host: :ip)
  ```

  Options:
    * `:host` - Host to use for the node. Supports `:ip`, `:dhcp`, `:hostname`
      or any binary or charlist
    * `:force` - Force node to be stopped if already running
    * `:type` - See Node.start/3
    * `:tick_time` - See Node.start/3
  """
  @spec start(node(), keyword(host: node_host())) :: node_return()
  def start(node_name, opts \\ []) do
    build_node(node_name, opts[:host])
    |> start_node(opts)
  end

  defp build_node(nil, _host), do: nil

  defp build_node(node, node_host) when is_atom(node) do
    node_str = to_string(node)

    if String.contains?(node_str, "@") do
      node
    else
      build_node(node_str, node_host)
    end
  end

  defp build_node(node_name, node_host) do
    node_host = resolve_node_host(node_host)

    if node_name && node_host do
      :"#{node_name}@#{node_host}"
    end
  end

  defp resolve_node_host(nil), do: resolve_node_host(:mdns)

  defp resolve_node_host(:mdns) do
    case MdnsLite.Configuration.get_mdns_config() do
      %{host: :hostname} -> resolve_node_host(:hostname)
      %{host: host} -> "#{host}.local"
      _ -> resolve_node_host(:ip)
    end
  end

  defp resolve_node_host(:dhcp) do
    with {:ok, hostname} <- :inet.gethostname(),
         {:ok, {:hostent, dhcp_name, _, _, _, _}} <- :inet.gethostbyname(hostname) do
      dhcp_name
    else
      _ -> resolve_node_host(:ip)
    end
  end

  defp resolve_node_host(:hostname) do
    {:ok, host} = :inet.gethostname()
    "#{host}.local"
  end

  defp resolve_node_host(:ip) do
    ips =
      VintageNet.match(["interface", :_, "addresses"])
      # Simplify structure a bit to {ifname, addresses}
      |> Enum.map(fn {[_, ifname, _], addrs} -> {ifname, addrs} end)
      |> Enum.sort()

    # Run through all known connected IP addresses prefering the order
    # of ethernet, wlan, then USB and halt on the first one discovered
    Enum.reduce_while(["eth", "wlan", "usb"], nil, fn ifname, acc ->
      case Enum.find(ips, &String.starts_with?(elem(&1, 0), ifname)) do
        {_, [%{address: addr} | _tail]} ->
          {:halt, VintageNet.IP.ip_to_string(addr)}

        _ ->
          {:cont, acc}
      end
    end)
  end

  defp resolve_node_host(host) when is_binary(host), do: host

  defp resolve_node_host(_host), do: nil

  defp start_epmd() do
    :os.cmd('epmd -daemon')
  end

  defp start_node(node, opts) when is_atom(node) and not is_nil(node) do
    # Aggressibely ensure epmd daemon is running
    # noop if daemon is already started
    _ = start_epmd()

    # Force the node to stop and restart with new settings
    _ = if opts[:force] == true, do: stop()

    args = [node | Keyword.take(opts, [:type, :tick_time])]
    apply(Node, :start, args)
  end

  defp start_node(node, _opts) do
    {:error, "Bad node: #{inspect(node)}"}
  end
end
