defmodule NervesPack.WiFiWizardButton do
  use GenServer

  @moduledoc """
  Starts the wizard if a button is depressed for long enough.

  **Note:** Using this requires `Circuits.GPIO` be included as a dependency in
  your project:

  ```elixir
  def deps() do
    {:circuits_gpio, "~> 0.4"}
  end
  ```

  It is recommended that you start this in your own supverision separate from
  NervesPack. This module mainly serves as a convenience and example for simple
  management of `VintageNetWizard`:

  ```elixir
  def start(_type, _args) do
    children = [
      NervesPack.WiFiWizardButton
      ...
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```

  Though you can also enable this in the config as well which will start it
  within `NervesPack.Supervisor` instead:

  ```
  config :nerves_pack, wifi_wizard_button: true
  ```

  GPIO 26 is used for the button and the hold time is 5 seconds.
  These defaults can be configured when adding as a supervised child or in the
  config if desired:

  ```
  # Supervised child
  children = [
    {NervesPack.WiFiWizardButton, [pin: 12, hold: 4_000]},
    ...
  ]

  # config.exs
  config :nerves_pack,
    wifi_wizard_button_pin: 17,
    wifi_wizard_button_hold: 3_000
  ```
  """

  alias Circuits.GPIO

  require Logger

  @default_hold 5_000
  @default_pin 26

  @doc """
  Start the button monitor
  """
  @spec start_link(list()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    if Code.ensure_compiled?(GPIO) do
      GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    else
      _ =
        Logger.warn("""
        [NervesPack] - Skipping WiFiWizardButton: add {:circuits_gpio, "~> 0.4"} to your dependencies to use
        """)

      :ignore
    end
  end

  @impl true
  def init(opts) do
    gpio_pin =
      opts[:pin] || Application.get_env(:nerves_pack, :wifi_wizard_button_pin, @default_pin)

    {:ok, gpio} = GPIO.open(gpio_pin, :input)
    :ok = GPIO.set_interrupts(gpio, :both)

    hold =
      opts[:hold] || Application.get_env(:nerves_pack, :wifi_wizard_button_hold, @default_hold)

    hold = validate_timeout(hold)

    _ =
      Logger.info("""
      [NervesPack] WiFi Wizard can be started any time by pressing down the button
      on GPIO #{gpio_pin} for #{hold / 1000} seconds.

      If no button is connected, you can manually mock a "press" by connecting the
      pin to 3.3v power for the required time with a cable.
      """)

    {:ok, %{hold: hold, pin: gpio_pin, gpio: gpio}}
  end

  @impl true
  def handle_info({:circuits_gpio, gpio_pin, _timestamp, 1}, %{pin: gpio_pin} = state) do
    # Button pressed. Start a timer to launch the wizard when it's long enough
    {:noreply, state, state.hold}
  end

  @impl true
  def handle_info({:circuits_gpio, gpio_pin, _timestamp, 0}, %{pin: gpio_pin} = state) do
    # Button released. The GenServer timer is implicitly cancelled by receiving this message.
    {:noreply, state}
  end

  @impl true
  def handle_info(:timeout, state) do
    # Timeout occurred before button released which means
    # it was held for long enough
    :ok = VintageNetWizard.run_wizard()
    _ = Logger.info("[NervesPack] WiFi Wizard started...")
    {:noreply, state}
  end

  defp validate_timeout(timeout) when is_integer(timeout), do: timeout

  defp validate_timeout(timeout) do
    _ =
      Logger.warn(
        "[NervesPack] Invalid button hold: #{inspect(timeout)}. Must be an integer in ms. Using default 5_000"
      )

    @default_hold
  end
end
