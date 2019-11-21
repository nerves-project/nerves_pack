# NervesPack

This library is a compilation of dependecies and default configuration
for getting a Nerves project up and running with minimal work. 
Essentially `nerves_init_gadget` 2.0 to work with new networking
libraries and practices. When added to your project, the following 
services are enabled by default:

* **Networking** - Ethernet, WiFi (without networks), and USB Gadget are
started by default if a supporting interface is discovered on the device
* **mDNS** - supports `nerves.local` and the default hostname (i.e. `nerves-1234.local`)
This is also configurable to other hostnames as well.
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
However, since it controls the networking and SSH interface, it is 
recommended to use it with [`shoehorn`](https://github.com/nerves-project/shoehorn)
to start it up separately so you still have access to your device in the event that the main application fails. This can be done by adding to your
`config.exs`

```elixir
config :shoehorn,
  init: [:nerves_runtime, :nerves_pack],
  app: Mix.Project.config()[:app]
```

