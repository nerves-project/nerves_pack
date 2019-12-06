# Changelog

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
