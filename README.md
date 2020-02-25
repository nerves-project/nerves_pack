# Nerves Pack

[![Hex version](https://img.shields.io/hexpm/v/nerves_pack.svg "Hex version")](https://hex.pm/packages/nerves_pack)
[![CircleCI](https://circleci.com/gh/nerves-project/nerves_pack.svg?style=svg)](https://circleci.com/gh/nerves-project/nerves_pack)

This library is a compilation of dependencies and default configuration for
getting a Nerves project up and running with minimal work. Essentially
`nerves_init_gadget` 2.0 to work with new networking libraries and practices.

When added to your project, the following services are enabled by default:

* **Networking** - Utilizes `VintageNet`. Ethernet and USB Direct are started by
  default if a supporting interface is discovered on the device
* **mDNS** - via `MdnsLite`. Supports `nerves.local` and the default hostname (i.e.
  `nerves-1234.local`) This is also configurable to other hostnames as well.
* **SSH** - Includes SSH access, firmware updates over SSH, and SFTP

## Installation

```elixir
def deps do
  [
    {:nerves_pack, "~> 0.1.0"}
  ]
end
```

This will start `NervesPack` and all its services with your application.
However, since it controls the networking and SSH interface, it is recommended
to use it with [`shoehorn`](https://github.com/nerves-project/shoehorn) to start
it up separately so you still have access to your device in the event that the
main application fails. This can be done by adding to your `config.exs`

```elixir
config :shoehorn,
  init: [:nerves_runtime, :nerves_pack],
  app: Mix.Project.config()[:app]
```

## SSH port

By default, `nerves_pack` will start an IEx console on port 22, this can be
overridden by specifying `:ssh_port` in the config. The SFTP subsystem is also
enabled so that you can transfer files back and forth as well. To disable this
feature, set `:ssh_port` to `nil`.  This console will use the same ssh public
keys as those configured for `:nerves_firmware_ssh` (see [the
docs](https://hexdocs.pm/nerves_firmware_ssh/readme.html#installation) for how
to configure your keys). Usernames are ignored.

```elixir
config :nerves_pack, ssh_port: 2222
```

Connect by running:

```bash
ssh nerves.local
```

To exit the SSH session, type `exit` or type the ssh escape sequence `~.` . (See
the [ssh man page](https://linux.die.net/man/1/ssh) for other escape sequences).
Typing `Ctrl+D` or `logoff` at the IEx prompt to exit the session won't work.

## Erlang distribution

`nerves_pack` does not start Erlang distribution. Distribution is not hard to
enable, but it requires some thought on node naming and security.

Erlang distribution requires that the hostname part of the device's node name be
reachable from the computer that's trying to connect. Options include IP
addresses, DNS names, mDNS names or names that you put in your `/etc/hosts`
file. Many Nerves users use mDNS names for simplicity, but they have
limitations. You may need to adjust the following script based on your
environment.

The Nerves project generator configures
[`mdns_lite`](https://github.com/pcmarks/mdns_lite) to advertise two hostnames:
`nerves.local` and `nerves-1234.local`. The latter one is based on the serial
number of the device. If you only have one Nerves device on the network, use
`nerves.local`. If you have many devices, you'll have to figure out the name
with the serial number. This can be done by using a mDNS discovery program or by
logging into a device via a serial console and typing `hostname` at the IEx
prompt.

The following uses `nerves.local`, but substitute for the name that you want.
Run this by `ssh`'ing into your Nerves device.

```elixir
iex> System.cmd("epmd", ["-daemon"])
{"", 0}
iex> Node.start(:"nerves@nerves.local")
{:ok, #PID<0.26318.2>}
iex(nerves@nerves.local)> Node.set_cookie(:my_secret_cookie)
true
```

For a programmatic implementation, see `:inet.gethostname/0` for constructing
a device-specific node name.

Now that Erlang distribution is running, try to connect to the device on your
computer.

```bash
$ iex --name me@0.0.0.0 --cookie my_secret_cookie --remsh nerves@nerves.local
Erlang/OTP 22 [erts-10.6.4] [source] [64-bit] [smp:32:32] [ds:32:32:10]
[async-threads:1] [hipe]

Interactive Elixir (1.9.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(nerves@nerves.local)1> use Toolshed
Toolshed imported. Run h(Toolshed) for more info
:ok
iex(nerves@nerves.local)2> cat "/proc/cpuinfo"
processor       : 0
model name      : ARMv6-compatible processor rev 7 (v6l)
BogoMIPS        : 697.95
Features        : half thumb fastmult vfp edsp java tls
CPU implementer : 0x41
CPU architecture: 7
CPU variant     : 0x0
CPU part        : 0xb76
CPU revision    : 7

Hardware        : BCM2835
Revision        : 9000c1
Serial          : 00000000b27aa712
Model           : Raspberry Pi Zero W Rev 1.1

iex(nerves@nerves.local)6>
```

## Optional WiFi wizard setup

_When_ and _how_ to start the WiFi wizard is generally very dependent on your
use-case so it's recommended that you implement the startup logic on your own.

See the [`vintage_net_wizard` docs](https://hexdocs.pm/vintage_net_wizard) for
more information on use and configuration.
