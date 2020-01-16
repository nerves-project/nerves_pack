defmodule NervesPack.SSH do
  @dialyzer {:no_opaque, start_ssh: 1}

  @moduledoc """
  Manages an ssh daemon.

  Currently piggy-backs off authorized keys defined for `NervesFirmwareSSH`
  and enables SFTP as a subsystem of SSH as well.

  It also configures and execution point so you can use `ssh` command
  to execute one-off Elixir code within IEx on the device and get the
  result back:

  ```sh
  $ ssh nerves.local "MyModule.hello()"
  :world
  ```
  """
  use GenServer

  @doc """
  Start an ssh daemon if ssh_port is not nil
  """
  def start_link(%{ssh_port: nil}), do: :ignore

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [opts], name: __MODULE__)
  end

  @impl true
  def init([opts]) do
    start_ssh(opts)
  end

  @spec start_ssh(%{:ssh_port => any}) ::
          {:ok, :ssh.daemon_ref()} | {:stop, reason :: any()}
  defp start_ssh(%{ssh_port: ssh_port}) do
    # Reuse `nerves_firmware_ssh` keys
    authorized_keys =
      Application.get_env(:nerves_firmware_ssh, :authorized_keys, [])
      |> Enum.join("\n")

    decoded_authorized_keys = :public_key.ssh_decode(authorized_keys, :auth_keys)

    cb_opts = [authorized_keys: decoded_authorized_keys]

    # Nerves stores a system default iex.exs. It's not in IEx's search path,
    # so run a search with it included.
    iex_opts = [dot_iex_path: find_iex_exs()]

    # Reuse the system_dir as well to allow for auth to work with the shared
    # keys.
    case :ssh.daemon(ssh_port, [
           {:id_string, :random},
           {:key_cb, {Nerves.Firmware.SSH.Keys, cb_opts}},
           {:system_dir, Nerves.Firmware.SSH.Application.system_dir()},
           {:shell, {Elixir.IEx, :start, [iex_opts]}},
           {:exec, &start_exec/3},
           # TODO: Split out NervesFirmwareSSH into subsystem here
           {:subsystems, [:ssh_sftpd.subsystem_spec(cwd: '/')]}
         ]) do
      {:ok, ssh} ->
        Process.link(ssh)
        {:ok, ssh}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  defp exec(cmd, _user, _peer) do
    try do
      {result, _env} = Code.eval_string(to_string(cmd))
      IO.inspect(result)
    catch
      kind, value ->
        IO.puts("** (#{kind}) #{inspect(value)}")
    end
  end

  defp find_iex_exs() do
    [".iex.exs", "~/.iex.exs", "/etc/iex.exs"]
    |> Enum.map(&Path.expand/1)
    |> Enum.find("", &File.regular?/1)
  end

  defp start_exec(cmd, user, peer) do
    spawn(fn -> exec(cmd, user, peer) end)
  end
end
