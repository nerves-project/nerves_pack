# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: CC0-1.0
#
defmodule Mix.Tasks.NervesPack.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  alias Igniter.Project.Deps

  # Igniter evaluates config/config.exs. In Nerves projects, that file starts
  # nerves_bootstrap, which logs since the archive isn't loaded.
  @moduletag capture_log: true

  @fixtures Path.expand("../../fixtures", __DIR__)
  @target_exs "config/target.exs"
  @iex_exs "rootfs_overlay/etc/iex.exs"

  # What `mix igniter.install nerves_pack` adds before it runs the installer
  @plain_dep {:nerves_pack, "~> 0.7"}

  # -- Helpers -----------------------------------------------------------------

  # The project that `mix igniter.new my_app --install nerves --target ...`
  # creates, made by running the real installers.
  defp nerves_project(targets \\ ["rpi4"]) do
    test_project()
    |> Igniter.compose_task("nerves.install", Enum.flat_map(targets, &["--target", &1]))
    |> apply_igniter!()
  end

  # A project that `mix nerves.new` created from its template. See
  # test/fixtures/README.md for how the fixtures were made.
  defp template_project(name) do
    root = Path.join(@fixtures, name)

    files =
      for path <- Path.wildcard(Path.join(root, "**"), match_dot: true),
          File.regular?(path),
          into: %{} do
        {Path.relative_to(path, root), File.read!(path)}
      end

    test_project(files: files)
  end

  # A project with only the files that matter to the installer
  defp project(target_exs, opts \\ []) do
    deps =
      Keyword.get(
        opts,
        :deps,
        ~s|{:nerves_system_rpi4, "~> 2.0", runtime: false, targets: :rpi4}|
      )

    attributes = Keyword.get(opts, :attributes, "")

    mix_exs = """
    defmodule Test.MixProject do
      use Mix.Project
    #{attributes}
      def project do
        [
          app: :test,
          version: "0.1.0",
          deps: deps()
        ]
      end

      defp deps do
        [
          #{deps}
        ]
      end
    end
    """

    files = %{"mix.exs" => mix_exs, "rel/vm.args.eex" => "+C multi_time_warp\n"}
    files = if target_exs, do: Map.put(files, @target_exs, target_exs), else: files

    test_project(files: files)
  end

  defp add_dep(igniter, dep \\ @plain_dep) do
    igniter |> Deps.add_dep(dep) |> apply_igniter!()
  end

  defp install(igniter, argv \\ []) do
    Igniter.compose_task(igniter, "nerves_pack.install", argv)
  end

  defp content(igniter, path) do
    igniter.rewrite |> Rewrite.source!(path) |> Rewrite.Source.get(:content)
  end

  defp nerves_pack_notices(igniter) do
    Enum.filter(igniter.notices, &String.starts_with?(&1, "nerves_pack:"))
  end

  defp count(string, pattern), do: length(String.split(string, pattern)) - 1

  # Evaluates a config/target.exs like a build for a device does. The SSH
  # configuration reads public keys from the home directory, which can't be
  # changed for a running VM, so the lookup is pointed at a directory that
  # has one.
  defp eval_config(content, tmp_dir) do
    home = Path.join(tmp_dir, "home")
    File.mkdir_p!(Path.join(home, ".ssh"))
    File.write!(Path.join(home, ".ssh/id_ed25519.pub"), "ssh-ed25519 AAAAtestkey test@host\n")

    path = Path.join(tmp_dir, "target-#{System.unique_integer([:positive])}.exs")
    File.write!(path, String.replace(content, "System.user_home!()", inspect(home)))

    path
    |> Config.Reader.read!(env: :prod, target: :rpi4)
    |> Enum.map(fn {app, config} -> {app, Enum.sort(config)} end)
    |> Enum.sort()
  end

  # -- Tests -------------------------------------------------------------------

  describe "project created by mix nerves.install" do
    @describetag :tmp_dir

    test "config/target.exs evaluates to the same configuration as the template's",
         %{tmp_dir: tmp_dir} do
      igniter = nerves_project() |> add_dep() |> install() |> apply_igniter!()

      installed = eval_config(content(igniter, @target_exs), tmp_dir)

      template =
        [@fixtures, "nerves_new_2", @target_exs]
        |> Path.join()
        |> File.read!()
        |> eval_config(tmp_dir)

      for app <- [:vintage_net, :mdns_lite, :nerves_ssh] do
        assert installed[app] != nil
        assert installed[app] == template[app]
      end

      assert installed[:nerves_ssh] == [authorized_keys: ["ssh-ed25519 AAAAtestkey test@host\n"]]

      # Everything else that the template configures for devices is the same too
      assert installed == template
    end

    test "restricts the dependency to the project's targets" do
      igniter = nerves_project() |> add_dep() |> install()

      assert_has_patch(igniter, "mix.exs", """
      - |      {:nerves_pack, "~> 0.7"},
      + |      {:nerves_pack, "~> 0.7", targets: @all_targets},
      """)

      assert content(igniter, "mix.exs") =~ """
               use Mix.Project

               @all_targets [:rpi4]

               def project do
             """

      assert nerves_pack_notices(igniter) == []
      assert igniter.warnings == []
      assert igniter.issues == []
    end

    test "uses all of the project's targets" do
      igniter = nerves_project(["rpi4", "rpi0", "bbb"]) |> add_dep() |> install()

      assert content(igniter, "mix.exs") =~ "@all_targets [:rpi4, :rpi0, :bbb]\n"
    end

    test "adds the dependency if it's missing" do
      igniter = nerves_project() |> install()

      assert content(igniter, "mix.exs") =~ ~s|{:nerves_pack, "~> 0.7", targets: @all_targets}|
      assert content(igniter, "mix.exs") =~ "@all_targets [:rpi4]\n"
    end

    test "starts nerves_pack early instead of nerves_ssh" do
      nerves_project()
      |> add_dep()
      |> install()
      |> assert_has_patch(@target_exs, """
      - |config :nerves, application_sort: [init: [:logger_backends, :nerves_runtime]]
      + |config :nerves, application_sort: [init: [:logger_backends, :nerves_runtime, :nerves_pack]]
      """)
    end

    test "configures the clock to be advanced at boot above the SSH configuration" do
      igniter = nerves_project() |> add_dep() |> install()

      # `mix nerves.install` writes the erlinit configuration itself. It's
      # kept as is and the SSH configuration goes below it.
      target_exs = content(igniter, @target_exs)

      assert [_before, after_clock] =
               String.split(target_exs, "config :nerves, :erlinit, update_clock: true\n")

      assert after_clock =~
               "# Configure the device for SSH IEx prompt access and firmware updates"

      # The import of target-specific configuration has to stay last
      assert String.ends_with?(content(igniter, @target_exs), """
             config :nerves_ssh,
               authorized_keys: Enum.map(keys, &File.read!/1)

             # Import target specific config. This must remain at the bottom
             # of this file so it overrides the configuration defined above.
             # Uncomment to use target specific configurations

             # import_config "\#{Mix.target()}.exs"
             """)
    end

    test "configures the network interfaces in the template's order" do
      nerves_project()
      |> add_dep()
      |> install()
      |> assert_has_patch(@target_exs, """
      + |config :vintage_net,
      + |  regulatory_domain: "00",
      + |  config: [
      + |    {"usb0", %{type: VintageNetDirect}},
      + |    {"eth0", %{type: VintageNetEthernet, ipv4: %{method: :dhcp}}},
      + |    {"wlan0", %{type: VintageNetWiFi}}
      + |  ]
      + |
      + |config :mdns_lite,
      + |  hosts: [:hostname, "nerves"],
      """)
    end

    test "prints the message of the day and leaves the vm.args alone" do
      igniter = nerves_project() |> add_dep() |> install()

      assert content(igniter, @iex_exs) =~ "NervesMOTD.print()"
      assert_unchanged(igniter, ["rel/vm.args.eex", "config/config.exs", "config/host.exs"])
    end

    test "points to the Erlang distribution documentation" do
      nerves_project()
      |> add_dep()
      |> install()
      |> assert_has_patch("mix.exs", """
        |      overwrite: true,
      + |      # Erlang distribution is not started automatically.
      + |      # See https://nerves-pack.hexdocs.pm/readme.html#erlang-distribution
        |      cookie: "test_cookie",
      """)
    end

    test "doesn't add the members to the project's dependencies" do
      igniter = nerves_project() |> add_dep() |> install()

      for app <- ~w(vintage_net vintage_net_wifi mdns_lite nerves_ssh nerves_time nerves_motd) do
        refute content(igniter, "mix.exs") =~ "{:#{app},"
      end
    end

    test "is idempotent" do
      nerves_project()
      |> add_dep()
      |> install()
      |> apply_igniter!()
      |> install()
      |> assert_unchanged()
    end
  end

  describe "projects created by mix nerves.new" do
    test "nothing is changed in a Nerves 2 project" do
      igniter = template_project("nerves_new_2") |> install()

      assert_unchanged(igniter)
      assert nerves_pack_notices(igniter) == []
      assert igniter.warnings == []
      assert igniter.issues == []
    end

    test "nothing is changed in a Nerves 1.x project" do
      igniter = template_project("nerves_new_1") |> install()

      assert_unchanged(igniter)
      assert nerves_pack_notices(igniter) == []
      assert igniter.warnings == []
      assert igniter.issues == []
    end

    test "the Nerves 1.x project is detected without Nerves.Igniter" do
      igniter = template_project("nerves_new_1")

      assert Mix.Tasks.NervesPack.Install.project_targets(igniter, false) == [:rpi4]
      assert Mix.Tasks.NervesPack.Install.project_targets(igniter, true) == [:rpi4]
    end
  end

  describe "early start" do
    test "adds nerves_pack to shoehorn's list" do
      igniter =
        project("""
        import Config

        config :shoehorn, init: [:nerves_runtime]
        """)
        |> add_dep()
        |> install()

      assert content(igniter, @target_exs) =~
               "config :shoehorn, init: [:nerves_runtime, :nerves_pack]"

      refute content(igniter, @target_exs) =~ ":nerves_ssh]"
    end

    test "updates a list in config/config.exs" do
      igniter =
        test_project(
          files: %{
            "config/config.exs" => """
            import Config

            config :nerves, application_sort: [init: [:nerves_runtime]]
            """,
            @target_exs => "import Config\n"
          }
        )
        |> add_dep()
        |> install()

      assert content(igniter, "config/config.exs") =~ "init: [:nerves_runtime, :nerves_pack]"
    end

    test "doesn't create a list" do
      igniter = project("import Config\n") |> add_dep() |> install()

      refute content(igniter, @target_exs) =~ "application_sort"
      refute content(igniter, @target_exs) =~ "shoehorn"
    end

    test "leaves lists that already have nerves_pack or aren't literals alone" do
      target_exs = """
      import Config

      early = [:nerves_runtime]
      config :nerves, application_sort: [init: early]
      config :shoehorn, init: [:nerves_pack, :nerves_runtime]
      """

      igniter = project(target_exs) |> add_dep() |> install()

      assert content(igniter, @target_exs) =~ "config :nerves, application_sort: [init: early]"

      assert content(igniter, @target_exs) =~
               "config :shoehorn, init: [:nerves_pack, :nerves_runtime]"
    end
  end

  describe "dependency" do
    test "keeps a :targets option that's already there" do
      igniter =
        project("import Config\n",
          deps: """
          {:nerves_pack, "~> 0.7", targets: [:rpi4]},
                {:nerves_system_rpi4, "~> 2.0", runtime: false, targets: :rpi4},
                {:nerves_system_rpi0, "~> 2.0", runtime: false, targets: :rpi0}
          """
        )
        |> install()

      assert_unchanged(igniter, "mix.exs")
      assert nerves_pack_notices(igniter) == []
    end

    test "uses an existing @all_targets attribute" do
      igniter =
        project("import Config\n",
          attributes: "\n  @all_targets [:rpi0, :custom]\n",
          deps: ~s|{:nerves_pack, "~> 0.7"}|
        )
        |> install()

      assert content(igniter, "mix.exs") =~ ~s|{:nerves_pack, "~> 0.7", targets: @all_targets}|
      assert count(content(igniter, "mix.exs"), "@all_targets [") == 1
    end

    test "puts @all_targets below the other module attributes" do
      igniter =
        project("import Config\n", attributes: "\n  @app :test\n  @version \"0.1.0\"\n")
        |> add_dep()
        |> install()

      assert content(igniter, "mix.exs") =~ """
               @app :test
               @version "0.1.0"
               @all_targets [:rpi4]

               def project do
             """
    end

    test "keeps the other options of the dependency" do
      # This is how Igniter writes `mix igniter.install nerves_pack@path:../nerves_pack`
      igniter =
        project("import Config\n")
        |> add_dep({:nerves_pack, path: "../nerves_pack", override: true})
        |> install()

      assert content(igniter, "mix.exs") =~
               ~s|{:nerves_pack, [path: "../nerves_pack", override: true, targets: @all_targets]}|

      igniter =
        project("import Config\n",
          deps: """
          {:nerves_pack, github: "nerves-project/nerves_pack"},
                {:nerves_system_rpi4, "~> 2.0", runtime: false, targets: :rpi4}
          """
        )
        |> install()

      assert content(igniter, "mix.exs") =~
               ~s|{:nerves_pack, github: "nerves-project/nerves_pack", targets: @all_targets}|
    end

    test "is left unrestricted with a notice when the targets are unknown" do
      igniter =
        project("import Config\n",
          deps: ~s|{:my_system, "~> 1.0", runtime: false, targets: :my_board}|
        )
        |> add_dep()
        |> install()

      assert content(igniter, "mix.exs") =~ ~s|{:nerves_pack, "~> 0.7"}|
      refute content(igniter, "mix.exs") =~ "@all_targets"
      assert [notice] = nerves_pack_notices(igniter)
      assert notice =~ "the targets of this project couldn't be determined"

      # Everything else is still set up
      assert content(igniter, @target_exs) =~ "config :vintage_net"
    end

    test "the fallback for finding targets handles the ways of writing them" do
      igniter =
        project("import Config\n",
          deps: """
          {:nerves_system_rpi4, "~> 2.0", runtime: false, targets: :rpi4},
                {:nerves_system_rpi0, path: "../rpi0", targets: [:rpi0, :rpi0_w]},
                {:nerves_system_bbb, "~> 2.0", runtime: false, targets: @bbb},
                {:nerves_system_x86_64, "~> 1.0", runtime: false},
                {:other, "~> 1.0", targets: :other}
          """
        )

      assert Mix.Tasks.NervesPack.Install.project_targets(igniter, false) ==
               [:rpi4, :rpi0, :rpi0_w]
    end
  end

  describe "existing configuration" do
    @describetag :tmp_dir

    @configured """
    import Config

    config :nerves, application_sort: [init: [:nerves_runtime, :nerves_pack]]

    config :nerves, :erlinit, ctty: "ttyAMA0"

    config :nerves_ssh, authorized_keys: ["ssh-ed25519 AAAAmine"]

    config :vintage_net,
      regulatory_domain: "SE",
      config: [
        {"eth0",
         %{
           type: VintageNetEthernet,
           ipv4: %{method: :static, address: "10.0.0.2", prefix_length: 24}
         }},
        {"wlan0", %{type: VintageNetWiFi}},
        {"usb0", %{type: VintageNetDirect}}
      ]

    config :mdns_lite,
      hosts: ["my-device"],
      ttl: 60,
      services: []
    """

    test "is preserved", %{tmp_dir: tmp_dir} do
      igniter =
        project(@configured,
          deps: """
          {:nerves_pack, "~> 0.7", targets: [:rpi4]},
                {:nerves_system_rpi4, "~> 2.0", runtime: false, targets: :rpi4}
          """
        )
        |> Igniter.create_new_file(@iex_exs, "NervesMOTD.print(logo: \"\")\n")
        |> apply_igniter!()
        |> install()

      assert_unchanged(igniter)

      assert eval_config(content(igniter, @target_exs), tmp_dir)[:vintage_net] == [
               config: [
                 {"eth0",
                  %{
                    type: VintageNetEthernet,
                    ipv4: %{method: :static, address: "10.0.0.2", prefix_length: 24}
                  }},
                 {"wlan0", %{type: VintageNetWiFi}},
                 {"usb0", %{type: VintageNetDirect}}
               ],
               regulatory_domain: "SE"
             ]
    end

    test "only gets what's missing" do
      target_exs = """
      import Config

      config :vintage_net,
        regulatory_domain: "SE",
        config: [{"wlan0", %{type: VintageNetWiFi, vintage_net_wifi: %{networks: []}}}]

      import_config "\#{Mix.target()}.exs"
      """

      igniter = project(target_exs) |> add_dep() |> install()
      result = content(igniter, @target_exs)

      assert result =~ ~s|regulatory_domain: "SE"|
      assert result =~ ~s|{"wlan0", %{type: VintageNetWiFi, vintage_net_wifi: %{networks: []}}}|
      assert result =~ ~s|{"usb0", %{type: VintageNetDirect}}|
      assert result =~ ~s|{"eth0", %{type: VintageNetEthernet, ipv4: %{method: :dhcp}}}|
      assert count(result, ~s|"wlan0"|) == 1
      assert result =~ "config :nerves, :erlinit, update_clock: true"
      assert String.ends_with?(result, "\nimport_config \"\#{Mix.target()}.exs\"\n")
    end
  end

  describe "options of the composed installers" do
    test "are part of the task's option schema" do
      info = Mix.Tasks.NervesPack.Install.info([], nil)

      assert info.schema == []

      for task <- info.composes do
        assert Mix.Task.get(task), "#{task} is composed, but doesn't exist"
      end

      # This raises on options that none of the composed installers define
      argv =
        ~w(--regulatory-domain US --hostname kiosk --ntp-server a.example.com --file iex.exs)

      assert {options, []} = Igniter.Util.Info.validate!(argv, info, "nerves_pack.install")
      assert options[:regulatory_domain] == "US"

      assert_raise OptionParser.ParseError, fn ->
        Igniter.Util.Info.validate!(["--no-such-option"], info, "nerves_pack.install")
      end
    end

    test "the regulatory domain is brought up once, and not when run again" do
      matching = fn igniter -> Enum.filter(igniter.notices, &(&1 =~ "regulatory domain")) end

      igniter = nerves_project() |> add_dep() |> install()
      assert [notice] = matching.(igniter)
      assert notice =~ ~s|the regulatory domain is "00"|

      igniter = igniter |> apply_igniter!() |> install()
      assert matching.(igniter) == []
      assert_unchanged(igniter)
    end

    test "--regulatory-domain" do
      igniter = nerves_project() |> add_dep() |> install(["--regulatory-domain", "us"])

      assert Enum.filter(igniter.notices, &(&1 =~ "regulatory domain")) == []

      assert content(igniter, @target_exs) =~ ~s|regulatory_domain: "US"|
    end

    test "--hostname" do
      igniter = nerves_project() |> add_dep() |> install(["--hostname", "kiosk"])

      assert content(igniter, @target_exs) =~ ~s|hosts: [:hostname, "kiosk"]|
    end

    test "--ntp-server" do
      igniter =
        nerves_project()
        |> add_dep()
        |> install(["--ntp-server", "a.example.com", "--ntp-server", "b.example.com"])

      assert content(igniter, @target_exs) =~
               ~s|config :nerves_time, servers: ["a.example.com", "b.example.com"]|
    end

    test "--file" do
      igniter =
        nerves_project() |> add_dep() |> install(["--file", "rootfs_overlay/etc/other.exs"])

      assert_creates(igniter, "rootfs_overlay/etc/other.exs", "NervesMOTD.print()\n")
      assert_unchanged(igniter, @iex_exs)
    end

    test "all at once are idempotent" do
      argv = ~w(--regulatory-domain US --hostname kiosk --ntp-server a.example.com)

      nerves_project()
      |> add_dep()
      |> install(argv)
      |> apply_igniter!()
      |> install(argv)
      |> assert_unchanged()
    end
  end

  describe "degrading" do
    test "nothing is configured in a project that isn't a Nerves project" do
      igniter = test_project() |> add_dep() |> install()

      assert_unchanged(igniter)
      assert [notice] = igniter.notices
      assert notice =~ "nerves_pack: this doesn't look like a Nerves project"
      assert notice =~ "mix igniter.install nerves nerves_pack"
      assert igniter.warnings == []
      assert igniter.issues == []
    end

    test "Nerves projects without a config/target.exs get the members' fallbacks" do
      igniter =
        project(nil,
          deps: """
          {:nerves, "~> 1.10", runtime: false},
                {:nerves_system_rpi4, "~> 1.0", runtime: false, targets: :rpi4}
          """
        )
        |> add_dep()
        |> install()

      assert content(igniter, "mix.exs") =~ ~s|{:nerves_pack, "~> 0.7", targets: @all_targets}|
      assert content(igniter, "config/config.exs") =~ "config :vintage_net"
      assert content(igniter, "config/config.exs") =~ "config :mdns_lite"
      assert content(igniter, "config/config.exs") =~ "config :nerves_ssh"
      refute content(igniter, "config/config.exs") =~ "erlinit"
      refute Igniter.exists?(igniter, @target_exs)
      assert_has_notice(igniter, &(&1 =~ "vintage_net: config/target.exs was not found"))
      assert nerves_pack_notices(igniter) == []
    end

    test "members without installers are reported in one notice" do
      igniter =
        nerves_project()
        |> add_dep()
        |> Igniter.assign(:nerves_pack_members,
          mdns_lite: "mdns_lite.install",
          # Doesn't exist
          vintage_net_qmi: "vintage_net_qmi.install",
          # Exists, but isn't an Igniter task
          compile: "compile",
          nerves_motd: "nerves_motd.install"
        )
        |> install()

      assert [notice] = nerves_pack_notices(igniter)
      assert notice =~ "the installers for vintage_net_qmi, compile weren't\navailable"
      assert notice =~ "mix deps.update vintage_net_qmi compile"
      assert igniter.issues == []

      # The others ran
      assert content(igniter, @target_exs) =~ "config :mdns_lite"
      assert content(igniter, @iex_exs) =~ "NervesMOTD.print()"
      refute content(igniter, @target_exs) =~ "config :vintage_net"
    end
  end
end
