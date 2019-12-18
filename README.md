# Nerves Pack

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

## Optional WiFi Wizard Setup

_When_ and _how_ to start the WiFi wizard is generally very dependent on your
use-case so it's recommended that you implement the startup logic on your own.
However,
[`vintage_net_wizard`](https://github.com/nerves-networking/vintage_net_wizard)
is included as an optional dependency and, for convenience, can be enabled with
a bit of configuration. When using via `NervesPack`, the WiFi Wizard will only
start if:

1) `vintage_net_wizard` is included in your project as a dependency
2) A `wlan` interface is available
3) `wlan` is not configured (including any saved configurations on disk)

To use, enable in your `config.exs`

```elixir
config :nerves_pack, wifi_wizard: true
```

See the [`vintage_net_wizard` docs](https://hexdocs.pm/vintage_net_wizard) for
more information on use and configuration.

## Using a button to manually start the WiFi Wizard

Another common case with the WiFi wizard is to allow starting it when a buttons
is pressed for a defined time. `NervesPack` provides an example implementation
for this and can be enabled through configuration. Like starting the wizard,
this can also have very specific handling logic and is recommended that you
implement your own setup according to your needs and use this as an example
during experimentation.

See the
[`WiFiWizardButton`](https://hexdocs.pm/nerves_pack/NervesPack.WiFiWizardButton.html)
documentation for how to enable and configure.
