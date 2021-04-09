use Mix.Config

config :nerves_runtime,
  target: "host"

# Overrides for unit tests:
#
# * resolvconf: don't update the real resolv.conf
# * persistence_dir: use the current directory
config :vintage_net,
  resolvconf: "/dev/null",
  persistence_dir: "./test_tmp/persistence"
