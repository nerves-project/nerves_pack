# Test fixtures

These are the files that the installer looks at from projects that `mix
nerves.new` (nerves_bootstrap 1.17) creates with `nerves_pack` support. They're
used to check that `mix nerves_pack.install` doesn't change such projects and
that it configures other projects the same way.

* `nerves_new_1` - `mix nerves.new my_app --target rpi4`
* `nerves_new_2` - `mix nerves.new my_app --target rpi4 --prerelease` (Nerves 2)

The files are verbatim copies, so they're excluded from `mix format`.
