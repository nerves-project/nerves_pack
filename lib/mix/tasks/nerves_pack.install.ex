# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: CC0-1.0
#
defmodule Mix.Tasks.NervesPack.Install.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc() do
    "Installs nerves_pack in your Nerves project."
  end

  @spec example() :: String.t()
  def example() do
    "mix igniter.install nerves_pack"
  end

  @spec long_doc() :: String.t()
  def long_doc() do
    """
    #{short_doc()}

    This sets up networking, mDNS, SSH, time synchronization and the message
    of the day the same way that `mix nerves.new` does. `nerves_pack` has no
    code of its own, so most of the work is done by the installers of the
    libraries that it brings in.

    ## Examples

    Add `nerves_pack` to a Nerves project:

    ```bash
    #{example()}
    ```

    Create a new Nerves project that has it:

    ```bash
    mix igniter.new my_app --install nerves,nerves_pack --target rpi4
    ```

    List `nerves` before `nerves_pack` so that the project's targets are known
    when `nerves_pack` is installed.

    ## What it does

    * Updates `mix.exs`:
        * Restricts the `:nerves_pack` dependency to devices with `targets:
          @all_targets`. The `@all_targets` module attribute is created from
          the targets of the project's Nerves systems if it doesn't exist.
          `nerves_pack` starts services that configure the network and set
          the clock, so it shouldn't be started on your computer.
        * Adds a pointer to the Erlang distribution documentation to the
          release options
    * Adds `:nerves_pack` to the applications that are started early
      (`config :nerves, application_sort: [init: [...]]` or `config
      :shoehorn, init: [...]`) if the project has such a list. This keeps the
      device reachable when your application fails to start.
    * Configures the device's clock to be advanced at boot (`config :nerves,
      :erlinit, update_clock: true`)
    * Runs these installers when the versions that were fetched have them:
        * `nerves_ssh.install` - authorizes your SSH public keys
        * `vintage_net.install`, `vintage_net_direct.install`,
          `vintage_net_ethernet.install` and `vintage_net_wifi.install` -
          configure the `usb0`, `eth0` and `wlan0` network interfaces
        * `mdns_lite.install` - advertises the device as `nerves.local`
        * `nerves_time.install` - checks the `vm.args` for time warp support
        * `nerves_motd.install` - prints the message of the day at the IEx
          prompt

    The device configuration goes in `config/target.exs`. Settings that are
    already present are kept, so it's safe to run this more than once and
    nothing is changed in a project that `mix nerves.new` created with
    `nerves_pack` support.

    If the project isn't a Nerves project, nothing is configured. Run `mix
    igniter.install nerves` first.

    ## Options

    This task has no options of its own. The options of the installers that it
    runs can be passed. For example:

    * `--regulatory-domain` - The ISO 3166-1 alpha-2 country code for where
      the device is used. This is needed for WiFi. (`vintage_net_wifi.install`)
    * `--hostname` - The mDNS hostname to advertise in addition to the
      device's own. Defaults to `nerves`. (`mdns_lite.install`)
    * `--ntp-server` - An NTP server to use instead of the defaults. May be
      repeated. (`nerves_time.install`)

    See the documentation of each installer for the complete list.
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.NervesPack.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    alias Igniter.Code.Common
    alias Igniter.Project.Config
    alias Igniter.Project.Deps

    @requirement (case Version.parse!(Mix.Project.config()[:version]) do
                    %Version{major: 0} = v -> "~> #{v.major}.#{v.minor}"
                    v -> "~> #{v.major}.0"
                  end)

    # The installers of the libraries that nerves_pack depends on.
    #
    # Igniter adds configuration for an application that isn't configured yet
    # to the top of the config file, so mdns_lite goes before vintage_net to
    # end up below it like in the `config/target.exs` that `mix nerves.new`
    # creates. The network interfaces are in that file's order: usb0, eth0,
    # wlan0.
    #
    # nerves_runtime and ring_logger are dependencies too, but every Nerves
    # project has them and `mix nerves.install` runs their installers.
    @members [
      nerves_ssh: "nerves_ssh.install",
      mdns_lite: "mdns_lite.install",
      vintage_net: "vintage_net.install",
      vintage_net_direct: "vintage_net_direct.install",
      vintage_net_ethernet: "vintage_net_ethernet.install",
      vintage_net_wifi: "vintage_net_wifi.install",
      nerves_time: "nerves_time.install",
      nerves_motd: "nerves_motd.install"
    ]

    # Lists of applications to start early: Nerves 2 and shoehorn (Nerves 1.x)
    @init_lists [{:nerves, [:application_sort, :init]}, {:shoehorn, [:init]}]

    @target_config "config/target.exs"

    @update_clock """
    # Erlinit can be configured without a rootfs_overlay. See
    # https://github.com/nerves-project/erlinit/ for more information on
    # configuring erlinit.

    # Advance the system clock on devices without a real-time clock.
    config :nerves, :erlinit, update_clock: true
    """

    @distribution_url "https://nerves-pack.hexdocs.pm/readme.html#erlang-distribution"

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :nerves_pack,
        example: __MODULE__.Docs.example(),
        schema: [],
        defaults: [],
        aliases: [],
        # The members are dependencies of nerves_pack, so they're fetched and
        # compiled with it. They're deliberately not listed under `installs`
        # or `adds_deps` since that would add them to the project's mix.exs.
        # Listing them here makes their options available.
        composes: Keyword.values(@members)
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      if nerves_project?(igniter) do
        igniter
        |> restrict_dep_to_targets()
        |> start_early()
        |> advance_clock_at_boot()
        |> install_members()
        |> add_distribution_comment()
      else
        add_not_nerves_notice(igniter)
      end
    end

    defp nerves_project?(igniter) do
      Igniter.exists?(igniter, @target_config) or Deps.has_dep?(igniter, :nerves)
    end

    # The libraries' own installers put their configuration in config.exs
    # when there's no target.exs. That's not done here: everything that
    # nerves_pack starts would then be configured for and run on the host.
    defp add_not_nerves_notice(igniter) do
      Igniter.add_notice(igniter, """
      nerves_pack: this doesn't look like a Nerves project (there's no
      config/target.exs and :nerves isn't a dependency), so nothing was
      configured.

      nerves_pack starts services that configure the network, set the clock
      and run an SSH server. It's meant to be used on Nerves devices and
      shouldn't be started on your computer. Turn the project into a Nerves
      project and rerun the installer with:

          mix igniter.install nerves nerves_pack

      Remove :nerves_pack from the dependencies in mix.exs if that isn't what
      you want.
      """)
    end

    # -- mix.exs ---------------------------------------------------------------

    defp restrict_dep_to_targets(igniter) do
      case dep_options(igniter) do
        nil ->
          igniter
          |> Deps.add_dep({:nerves_pack, @requirement}, append?: true, on_exists: :skip)
          |> set_dep_targets()

        options ->
          if Keyword.keyword?(options) and Keyword.has_key?(options, :targets) do
            igniter
          else
            set_dep_targets(igniter)
          end
      end
    end

    defp set_dep_targets(igniter) do
      cond do
        all_targets_attribute?(igniter) ->
          set_all_targets_option(igniter)

        (targets = project_targets(igniter)) != [] ->
          igniter = add_all_targets_attribute(igniter, targets)

          if all_targets_attribute?(igniter),
            do: set_all_targets_option(igniter),
            else: igniter

        true ->
          Igniter.add_notice(igniter, """
          nerves_pack: the targets of this project couldn't be determined, so the
          :nerves_pack dependency in mix.exs wasn't restricted to them. nerves_pack
          shouldn't be started on your computer. Change the dependency to list the
          targets that the project is built for. For example:

              {:nerves_pack, "#{@requirement}", targets: [:rpi4, :rpi5]}
          """)
      end
    end

    defp set_all_targets_option(igniter) do
      Deps.set_dep_option(igniter, :nerves_pack, :targets, {:@, [], [{:all_targets, [], nil}]})
    end

    # Returns the dependency's options, `[]` if it has none and `nil` if
    # nerves_pack isn't a dependency
    defp dep_options(igniter) do
      with {:ok, declaration} when is_binary(declaration) <- Deps.get_dep(igniter, :nerves_pack),
           {:ok, quoted} <- Code.string_to_quoted(declaration) do
        case quoted do
          {:{}, _, [:nerves_pack, _requirement, options]} when is_list(options) -> options
          {:nerves_pack, options} when is_list(options) -> options
          _ -> []
        end
      else
        _ -> nil
      end
    end

    defp all_targets_attribute?(igniter) do
      read(igniter, "mix.exs") =~ ~r/^\s*@all_targets\s/m
    end

    # `mix nerves.new` puts the attribute below `@version`, right above
    # `def project`. It's added as text to get the same blank lines.
    defp add_all_targets_attribute(igniter, targets) do
      Igniter.update_file(igniter, "mix.exs", fn source ->
        lines = source |> Rewrite.Source.get(:content) |> String.split("\n")

        case Enum.find_index(lines, &(&1 =~ ~r/^\s*def project\b/)) do
          nil ->
            {:warning,
             """
             nerves_pack: could not add `@all_targets #{inspect(targets)}` to mix.exs, so the
             :nerves_pack dependency wasn't restricted to devices. Add this option
             to it:

                 targets: #{inspect(targets)}
             """}

          index ->
            {above, rest} = Enum.split(lines, index)
            [indent] = Regex.run(~r/^\s*/, hd(rest))
            above = above |> Enum.reverse() |> Enum.drop_while(&(String.trim(&1) == ""))
            # Other module attributes are kept together with this one
            separator = if above != [] and hd(above) =~ ~r/^\s*@\w+ /, do: [], else: [""]
            attribute = "#{indent}@all_targets #{inspect(targets)}"
            lines = Enum.reverse(above) ++ separator ++ [attribute, ""] ++ rest

            Rewrite.Source.update(source, :content, Enum.join(lines, "\n"))
        end
      end)
    end

    @doc false
    # Returns the targets that the project has Nerves systems for. This is
    # `Nerves.Igniter.project_targets/1` when the project's Nerves has it.
    # nerves_pack doesn't depend on Nerves, so there's a fallback for when it
    # isn't available (Nerves 1.x).
    @spec project_targets(Igniter.t(), boolean()) :: [atom()]
    def project_targets(igniter, nerves_igniter? \\ nerves_igniter?()) do
      if nerves_igniter? do
        apply(Nerves.Igniter, :project_targets, [igniter])
      else
        case Code.string_to_quoted(read(igniter, "mix.exs")) do
          {:ok, quoted} ->
            {_quoted, targets} = Macro.prewalk(quoted, [], &collect_system_targets/2)
            targets |> Enum.reverse() |> Enum.uniq()

          {:error, _} ->
            []
        end
      end
    end

    defp nerves_igniter?() do
      Code.ensure_loaded?(Nerves.Igniter) and
        function_exported?(Nerves.Igniter, :project_targets, 1)
    end

    defp collect_system_targets({:{}, _, [app, _requirement, options]} = node, acc),
      do: {node, collect_system_targets(app, options, acc)}

    defp collect_system_targets({app, options} = node, acc) when is_list(options),
      do: {node, collect_system_targets(app, options, acc)}

    defp collect_system_targets(node, acc), do: {node, acc}

    defp collect_system_targets(app, options, acc) do
      with true <- is_atom(app) and Keyword.keyword?(options),
           "nerves_system_" <> _ <- Atom.to_string(app),
           targets = List.wrap(Keyword.get(options, :targets)),
           true <- Enum.all?(targets, &is_atom/1) do
        Enum.reverse(targets) ++ acc
      else
        _ -> acc
      end
    end

    # The template for new projects has this comment. It's only added to
    # release options that look like the template's.
    defp add_distribution_comment(igniter) do
      Igniter.update_file(igniter, "mix.exs", fn source ->
        content = Rewrite.Source.get(source, :content)

        with false <- content =~ @distribution_url,
             true <- content =~ ~r/Nerves\.(init_release|Release\.init)/,
             [[line, indent]] <- Regex.scan(~r/^([ \t]*)cookie:.*$/m, content) do
          comment = """
          #{indent}# Erlang distribution is not started automatically.
          #{indent}# See #{@distribution_url}
          """

          Rewrite.Source.update(source, :content, String.replace(content, line, comment <> line))
        else
          _ -> source
        end
      end)
    end

    # -- config ----------------------------------------------------------------

    # This is done before nerves_ssh's installer runs. It adds :nerves_ssh
    # to the list unless :nerves_pack is in it.
    defp start_early(igniter) do
      for {app, key_path} <- @init_lists,
          file <- ["target.exs", "config.exs"],
          Igniter.exists?(igniter, Path.join("config", file)),
          Config.configures_key?(igniter, file, app, key_path),
          reduce: igniter do
        igniter ->
          Config.configure(igniter, file, app, key_path, [:nerves_pack],
            updater: &append_to_init_list/1
          )
      end
    end

    # Anything other than a literal list is left alone
    defp append_to_init_list(zipper) do
      case Common.within(zipper, &append_nerves_pack/1) do
        {:ok, zipper} -> {:ok, zipper}
        :error -> {:ok, zipper}
      end
    end

    defp append_nerves_pack(list) do
      if Igniter.Code.List.list?(list) do
        Igniter.Code.List.append_new_to_list(list, :nerves_pack)
      else
        :error
      end
    end

    # nerves_time sets the clock once it has the time from the network or a
    # real-time clock. This makes sure that the clock isn't way off until
    # then. It's an option for Nerves, so it only goes in projects that have a
    # config/target.exs.
    defp advance_clock_at_boot(igniter) do
      if Igniter.exists?(igniter, @target_config) and not configures_erlinit?(igniter) do
        Igniter.update_file(igniter, @target_config, &add_update_clock/1)
      else
        igniter
      end
    end

    # Any erlinit configuration means that the user has looked at it
    defp configures_erlinit?(igniter) do
      Enum.any?(["target.exs", "config.exs"], fn file ->
        Igniter.exists?(igniter, Path.join("config", file)) and
          Config.configures_key?(igniter, file, :nerves, [:erlinit])
      end)
    end

    # The block is added as text since Sourceror can't insert code that has
    # comments into a file that ends with a comment, which is what the
    # config/target.exs of Nerves projects does. It goes above the trailing
    # `import_config` (commented out or not) so that what's imported can
    # override it.
    defp add_update_clock(source) do
      lines = source |> Rewrite.Source.get(:content) |> String.split("\n")
      index = import_config_index(lines) || length(lines)
      {before, rest} = Enum.split(lines, index)

      content =
        [trim_blank_lines(before), String.trim_trailing(@update_clock), trim_blank_lines(rest)]
        |> Enum.reject(&(&1 == ""))
        |> Enum.join("\n\n")

      Rewrite.Source.update(source, :content, content <> "\n")
    end

    # 0-based index of the first line of the last block of comments and
    # `import_config` lines if the file ends with one
    defp import_config_index(lines) do
      trailing =
        lines
        |> Enum.reverse()
        |> Enum.take_while(&(&1 =~ ~r/^\s*(#.*|import_config\b.*)?$/))

      if Enum.any?(trailing, &(&1 =~ "import_config")) do
        length(lines) - length(trailing)
      end
    end

    defp trim_blank_lines(lines), do: lines |> Enum.join("\n") |> String.trim()

    # -- Members ---------------------------------------------------------------

    # Whether an installer is available depends on which version of the
    # library was fetched. Libraries without one are skipped and reported
    # together.
    defp install_members(igniter) do
      members = igniter.assigns[:nerves_pack_members] || @members

      {igniter, missing} =
        Enum.reduce(members, {igniter, []}, fn {app, task}, {igniter, missing} ->
          if installer?(task) do
            {Igniter.compose_task(igniter, task), missing}
          else
            {igniter, [app | missing]}
          end
        end)

      case Enum.reverse(missing) do
        [] ->
          igniter

        missing ->
          names = Enum.map_join(missing, ", ", &to_string/1)

          Igniter.add_notice(igniter, """
          nerves_pack: the installers for #{names} weren't
          available, so they weren't configured. The versions that were fetched
          probably predate their installers. Try updating them and running this
          again:

              mix deps.update #{Enum.map_join(missing, " ", &to_string/1)}
              mix igniter.install nerves_pack

          If they're still not available, see the libraries' documentation for
          how to configure them.
          """)
      end
    end

    # Libraries define a placeholder task that isn't an Igniter task when
    # what their installer needs is missing. Igniter skips those silently.
    defp installer?(task_name) do
      case Mix.Task.get(task_name) do
        nil -> false
        task -> Igniter.Mix.Task.igniter_task?(task)
      end
    end

    # -- Utilities -------------------------------------------------------------

    defp read(igniter, path) do
      igniter
      |> Igniter.include_existing_file(path)
      |> Map.fetch!(:rewrite)
      |> Rewrite.source!(path)
      |> Rewrite.Source.get(:content)
    end
  end
else
  defmodule Mix.Tasks.NervesPack.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'nerves_pack.install' requires igniter. Please install igniter and try again.

      For more information, see: https://igniter.hexdocs.pm/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
