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
