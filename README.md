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

## Erlang Distribution

You can use `nerves_pack` to run your device as a distributed node by default
via configuration or at runtime with `NervesPack.Node.start/2`.

To run on startup, give your device a node name:

```elixir
config :nerves_pack, node_name: "mydevice"
```

Optionally, you can also specify how you would like the host configured and
`NervesPack` will do a best-effort attempt to configure the node accordingly:

```elixir
config :nerves_pack,
  node_name: "mydevice",
  node_host: :mdns
```

Supported `:host` options are:
* `:mdns` - Use the `host` set for `MdnsLite`. This will be in `*.local` form
* `:ip` - Read the IP address of the device. If multiple interfaces are
  connected, it will cycle through IP addresses on each interface and select the
  first one found preferring the order of `ethernet`, `wifi`, then `usb`
* `:dhcp` - Reads the assigned dhcp address based on the device hostname
* `:hostname` - Reads hostname of the device, assigning as `hostname.local`
* custom binary created by the user representing the host - `"testing.local"`

You can also skip any sort of deduction by `:nerves_pack` and supply a valid
node atom as well:

```elixir
config :nerves_pack, node_name: :"mydevice@nerves.local"
```

If you do not want `NervesPack` to handle starting as a distributed node, you
can skip application configuration and instead call at runtime:

```elixir
NervesPack.Node.start("mynode", host: :mdns)
```

See `NervesPack.Node.start/2` for more info.

It's also worth noting that _nerves <-> nerves_ communication won't work with
`:mdns` because the Erlang DNS resolver doesn't handle it and you may want to
use `:dhcp` or `:ip` with static addresses to handle it.

## SSH Port

By default, `nerves_pack` will start an IEx console on port 22, this can be overriden
by specifying `:ssh_port` in the config. The SFTP subsystem is also enabled
so that you can transfer files back and forth as well. To disable this feature,
set `:ssh_port` to `nil`.  This console will use the same ssh public
keys as those configured for `:nerves_firmware_ssh` (see [the
docs](https://hexdocs.pm/nerves_firmware_ssh/readme.html#installation) for how to
configure your keys). Usernames are ignored.

```elixir
config :nerves_pack, ssh_port: 2222
```

Connect by running:

```bash
ssh nerves.local
```

To exit the SSH session, type `exit` or type the ssh escape sequence `~.` . (See the
[ssh man page](https://linux.die.net/man/1/ssh) for other escape sequences).
Typing `Ctrl+D` or `logoff` at the IEx prompt to exit the session won't work.

## Optional WiFi Wizard Setup

_When_ and _how_ to start the WiFi wizard is generally very dependent on your
use-case so it's recommended that you implement the startup logic on your own.

See the [`vintage_net_wizard` docs](https://hexdocs.pm/vintage_net_wizard) for
more information on use and configuration.
