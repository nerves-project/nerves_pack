defmodule NervesPack.WiFiWizardButton do
  use GenServer

  @moduledoc """
  This GenServer starts the wizard if a button is depressed for long enough.

  GPIO 26 is used for the button and the hold time is 5 seconds.
  These defaults can be configured in the config if desired:

  ```
  config :nerves_pack,
    wifi_wizard_button_pin: 17,
    wifi_wizard_button_hold: 3_000
  ```

  You can also disable using a button to start the WiFi wizard
  in the config as well:

  ```
  config :nerves_pack, wifi_wizard_button: false
  ```
  """

  alias Circuits.GPIO

  require Logger

  @doc """
  Start the button monitor
  """
  @spec start_link(list()) :: GenServer.on_start()
  def start_link(_opts \\ []) do
    gpio_pin = Application.get_env(:nerves_pack, :wifi_wizard_button_pin, 26)
    GenServer.start_link(__MODULE__, gpio_pin, name: __MODULE__)
  end

  @impl true
  def init(gpio_pin) do
    {:ok, gpio} = GPIO.open(gpio_pin, :input)
    :ok = GPIO.set_interrupts(gpio, :both)

    timeout =
      Application.get_env(:nerves_pack, :wifi_wizard_button_hold, 5_000)
      |> validate_timeout()

    Logger.info("""
    [NervesPack] WiFi Wizard can be started any time by pressing down the button
    on GPIO #{gpio_pin} for #{timeout / 1000} seconds.

    If no button is connected, you can manually mock a "press" by connecting the
    pin to 3.3v power for the required time with a cable.
    """)

    {:ok, %{button_timeout: timeout, pin: gpio_pin, gpio: gpio}}
  end

  @impl true
  def handle_info({:circuits_gpio, gpio_pin, _timestamp, 1}, %{pin: gpio_pin} = state) do
    # Button pressed. Start a timer to launch the wizard when it's long enough
    {:noreply, state, state.button_timeout}
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
    Logger.info("[NervesPack] WiFi Wizard started...")
    {:noreply, state}
  end

  defp validate_timeout(timeout) when is_integer(timeout), do: timeout

  defp validate_timeout(timeout) do
    Logger.warn(
      "[NervesPack] Invalid button hold: #{inspect(timeout)}. Must be an integer in ms. Using default 5_000"
    )
  end
end
