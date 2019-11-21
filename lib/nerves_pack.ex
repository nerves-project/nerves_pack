defmodule NervesPack do
  @moduledoc """
  This library is a compilation of dependecies and default configuration
  for getting a Nerves project up and running with minimal work. When
  added to your project, the following services are enabled by default:

  * **Networking** - Ethernet, WiFi (without networks), and USB Gadget are
  started by default if a supporting interface is discovered on the device
  * **mDNS** - supports `nerves.local` and the default hostname (i.e. `nerves-1234.local`)
  This is also configurable to other hostnames as well.
  * **WiFi Setup Wizard** - Utilizing `VintageNetWizard` to set device to AP host mode to
  provide a website for configuring WiFi networks from a broswer. This is enabled by default
  if `wlan` interface is available but not configured previously or by `config.exs`.
  See [`vintage_net_wizard` library](https://github.com/nerves-networking/vintage_net_wizard) for more info.
  * **SSH** - Includes SSH access, firmware updates over SSH, and SFTP
  * **Circuits GPIO** - Interfacing with GPIO via [`circuits_gpio`](https://github.com/elixir-circuits/circuits_gpio)
  """
end
