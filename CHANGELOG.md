# Changelog

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
