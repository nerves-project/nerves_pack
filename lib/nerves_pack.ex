defmodule NervesPack do
  @moduledoc """
  This library is a compilation of dependecies and default configuration
  for getting a Nerves project up and running with minimal work. When
  added to your project, the following services are enabled by default:

  * **Networking** - Ethernet, WiFi (without networks), and USB Gadget are
  started by default if a supporting interface is discovered on the device
  * **mDNS** - supports `nerves.local` and the default hostname (i.e. `nerves-1234.local`)
  This is also configurable to other hostnames as well.
  * **SSH** - Includes SSH access, firmware updates over SSH, and SFTP
  """
end
