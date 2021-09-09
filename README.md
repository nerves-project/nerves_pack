# Nerves Pack

[![Hex version](https://img.shields.io/hexpm/v/nerves_pack.svg "Hex version")](https://hex.pm/packages/nerves_pack)
[![CircleCI](https://circleci.com/gh/nerves-project/nerves_pack.svg?style=svg)](https://circleci.com/gh/nerves-project/nerves_pack)

A compilation of dependencies and default configuration for getting Nerves
projects up and running with minimal work.

When added to your project, Nerves Pack brings in the following services and
support libraries:

* **Networking**, using [`VintageNet`](https://hex.pm/packages/vintage_net).
* **mDNS**, via [`MdnsLite`](https://hex.pm/packages/mdns_lite).
* **SSH**, via [`NervesSSH`](https://hex.pm/packages/nerves_ssh). Includes:
  * regular SSH access
  * firmware updates subsystem via [`SSHSubsystemFwup`](https://hex.pm/packages/ssh_subsystem_fwup)
  * SFTP subsystem
  * Ability to configure more subsystems as needed
* **Time**, via [`NervesTime`](https://hex.pm/packages/nerves_time)
* **Logging**, via [`RingLogger`](https://hex.pm/packages/ring_logger)
* **MOTD**, via [`NervesMOTD`](https://hex.pm/packages/nerves_motd)

Nerves Pack only contains dependencies. There's no code in this library. Once
you find that you want to customize what's included in your project, just remove
the `:nerves_pack` dependency and add the dependencies you need.

When updating old Nerves project, Nerves Pack is the new version of
`nerves_init_gadget`. The main change will be moving your `:nerves_networking`
configuration to VintageNet.

## Installation

```elixir
def deps do
  [
    {:nerves_pack, "~> 0.4.1"}
  ]
end
```

This will start `NervesPack` and all its services with your application.
However, since it controls the networking and SSH interface, it is recommended
to use it with [`shoehorn`](https://github.com/nerves-project/shoehorn) to start
it up separately so you still have access to your device in the event that the
main application fails. This can be done by adding `shoehorn` to your
`config.exs`:

```elixir
config :shoehorn,
  init: [:nerves_runtime, :nerves_pack],
  app: Mix.Project.config()[:app]
```

## mDNS

mDNS is an protocol that makes it easier to find the IP addresses of Nerves
devices on a LAN. `nerves_pack` pulls in
[`mdns_lite`](https://github.com/nerves-networking/mdns_lite) to help with this
and the default Nerves new project generator adds a default configuration that
lets you connect to your Nerves device via the names, `nerves.local` or
`nerves-wxyz.local` where `wxyz` are part of the device's unique identifier.
Device identifers are device-specific and can be found by typing `hostname` at
the IEx prompt.

If you are converting a project to use `nerves_pack`, here's a starter
configuration to paste into your config:

```elixir
config :mdns_lite,
  # The `host` key specifies what hostnames mdns_lite advertises.  `:hostname`
  # advertises the device's hostname.local. For the official Nerves systems, this
  # is "nerves-<4 digit serial#>.local".  mdns_lite also advertises
  # "nerves.local" for convenience. If more than one Nerves device is on the
  # network, delete "nerves" from the list.

  host: [:hostname, "nerves"],
  ttl: 120,

  # Advertise the following services over mDNS.
  services: [
    %{
      protocol: "ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "sftp-ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "epmd",
      transport: "tcp",
      port: 4369
    }
  ]
```

## SSH port

`nerves_pack` depends on
[`nerves_ssh`](https://github.com/nerves-project/nerves_ssh). `nerves_ssh`
starts up an SSH server on port 22 (the default SSH port) that provides an IEx
console, SFTP, and firmware update support. See the `nerves_ssh` documentation
for changing the configuration.

By default, the Nerves new project generator creates projects that include your
SSH public key (from `~/.ssh/id_rsa`, etc.) in your `config.exs` under the
`nerves_ssh` configuration. It is possible that your project has this
configuration under the `nerves_firmware_ssh` key. If so, you will receive an
error directing you to update your configuration.

The use of SSH public keys lets you log into your Nerves devices, but no one
else.  See [the
docs](https://hexdocs.pm/nerves_firmware_ssh/readme.html#installation) for how
to configure your keys). Usernames are ignored.

Connect by running:

```bash
ssh nerves.local
```

If your computer has trouble with mDNS, you may need to replace `nerves.local`
with the device's IP address. This is more of an issue on Windows than Linux or
OSX. See your router or use a port scanner like `nmap` to find the device.

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
`nerves.local`. But, if you have many devices, figure out each hostname
from the device's serial number, either by using a mDNS discovery program or by
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
