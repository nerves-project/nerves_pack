# Changelog

## v0.7.0

* Potentially Breaking Changes
  * Bump minimums to Elixir >= 1.10 / OTP >= 23

## v0.6.0

* Potentially Breaking Changes
  * Bump minimum Elixir to 1.9
  * Force upgrades to vintage_net and mdns_lite

## v0.5.0

Add `:nerves_motd` to the dependency list so that it's easy for projects to add
a nice login greeting.

## v0.4.2

This allows `v0.10` of the `vintage_net*` libraries.

Also bumps some dependencies

## v0.4.1

Removes automatic `mdns_lite` setup and shifts this project to be dependency
and documentation driven as an example of basic Nerves project setup.

* Fixes
  * Fixes a dependency ordering issue for Elixir 1.11. See https://github.com/nerves-project/nerves_pack/pull/42

## v0.4.0

This refactors SSH support to its own library so that projects not using
`nerves_pack` don't have to copy/paste the SSH code. `nerves_ssh` also
has several improvements to SSH support that will be easier to maintain
in a standalone project.

This also brings in the switch from `nerves_firmware_ssh` to
`ssh_subsystem_fwup` which moves firmware updates from port 8989 to an
SSH subsystem on port 22. This is a breaking change for scripts that
load firmware to Nerves devices via SSH. See the
[`Upgrade from NervesFirmwareSSH`](https://hexdocs.pm/nerves_ssh/readme.html#upgrade-from-nervesfirmwaressh)
doc for more details on how to handle this change.

## v0.3.3

This allows `v0.9` of the `vintage_net*` libraries.

If you wish to update the `vintage_net*` libraries, be sure to look at
the [VintageNet `v0.9.0` Changelog](https://hexdocs.pm/vintage_net/changelog.html#v0-9-0)
as there are a few breaking changes that might need to be considered.

## v0.3.2

* Enhancements
  * Update ssh daemon to start with inet6

* Fixes
  * Remove automatic network configuration - This would interfere with
  predictable networking support and also made it impossible to deconfigure
  a network interface permanently

## v0.3.1

Few dependency and documentation updates.

There was a breaking change in `vintage_net 0.8` for anyone implementing a
custom technology. This doesn't affect most `nerves_pack` users except that
the dependency here on `vintage_net` allows `0.8` along with `0.7`.

## v0.3.0

This release removes the `vintage_net_wizard` setup helper. It turned out that
there was enough custom configuration that it was easier to configure the WiFi
wizard on its own rather than via `NervesPack`. If you had been using
`NervesPack` to configure the wizard, please see the [`vintage_net_wizard`
docs](https://hexdocs.pm/vintage_net_wizard).

## v0.2.2

* Enhancements
  * supervise `sshd` and allow port to be configured
  * Fix warnings when `vintage_net_wizard` is optional

## v0.2.1

* Enhancements
  * `:vintage_net_wizard` is now optional and using NervesPack default setup
    with it requires configuration
  * removes `:busybox` dependency since that is now included as part of the
    Nerves systems

## v0.2.0

* vintage_net 0.7

* Enhancements
  * `:vintage_net ~> 0.7` splits out networking technologies into their own
    libs. Deps have been updated to use this
  * `WiFiWizardButton` is now an opt-in so that `:circuits_gpio` can be a
    optional dependency to allow `NervesPack` to work with more systems

## v0.1.1

* mdns_lite 0.6.1
* vintage_net 0.6.6

* Enhancements
  * With new VintageNet and MdnsLite updates, mDNS host and services can be
    configured at runtime. This allows us to set basic defaults if no other
    options have been configured when starting to run
  * VintageNet and MdnsLite also brings in `VintageNetMonitor` which updates
    mDNS records whenever address changes happen (polling no longer required).
    This means faster mDNS response times.

## v0.1.0

Initial release
