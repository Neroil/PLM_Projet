defmodule EventManager do
  use GenServer

  @moduledoc """
  The EventManger handle the random event event
  that may happen during the game and the tax collection.
  """

  import StockMarket
  import Resource
  import RobotDynSupervisor
  import PlanetSupervisor

  alias Phoenix.PubSub

  @tax_collection_time 300_000

  @doc """
  Start the EventManager
  """
  def start_link(_) do
    IO.puts("EventManager starting...")

    events = [
      :market_up,   # The market's price go up
      :market_down, # The market's price go down
      :money_loss,  # The player loose some money
      :money_gain,  # The player gain some money
      :robot_loss   # Some robot are removed from an owned planet
    ]

    # Random events happend between a 10 to 60 seconds interval
    times = %{
      min: 10000,
      max: 60000
    }

    GenServer.start_link(__MODULE__, %{events: events, times: times}, name: __MODULE__)
  end

  @doc """
  Get the time before the next tax collection

  ## Return value
  `Integer` with the time remaining in seconds
  """
  def get_next_tax_countdown() do
    try do
      GenServer.call(__MODULE__, :get_next_tax_countdown)
    catch
      :exit, _ -> 0
    end
  end

  @impl true
  def init(state) do
    IO.puts("EventManager initialized - scheduling tax collection in 5 minutes")

    # Store the initial tax collection time
    next_tax_time = :erlang.system_time(:millisecond) + @tax_collection_time
    state = Map.put(state, :next_tax_time, next_tax_time)

    # Start the timers for the random events and the tax collection
    Process.send_after(self(), :nextEvent, 30000)
    Process.send_after(self(), :tax_collection, @tax_collection_time)

    {:ok, state}
  end

  @impl true
  def handle_info(:nextEvent, state) do
    #Make the event happen
    apply_event(Enum.random(state[:events]))

    # Schedule the next event
    Process.send_after(self(), :nextEvent, Enum.random(state[:times][:min]..state[:times][:max]))

    {:noreply, state}
  end

  @impl true
  def handle_info(:tax_collection, state) do
    collect_tax()

    # Update next tax collection time
    next_tax_time = :erlang.system_time(:millisecond) + @tax_collection_time
    state = Map.put(state, :next_tax_time, next_tax_time)

    # Schedule the next tax collection
    Process.send_after(self(), :tax_collection, @tax_collection_time)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_next_tax_countdown, _from, state) do
    # Get the time remaining
    current_time = :erlang.system_time(:millisecond)
    next_tax_time = Map.get(state, :next_tax_time, current_time + @tax_collection_time)

    # Transform the time in second
    remaining_ms = max(0, next_tax_time - current_time)
    remaining_seconds = div(remaining_ms, 1000)

    {:reply, remaining_seconds, state}
  end

  # Apply the effect of an event
  # event: Atom containing the event name
  defp apply_event(event) do
    IO.puts("#{event} is happening")

    case event do
      :market_up ->
        market_up()

      :market_down ->
        market_down()

      :money_loss ->
        money_loss()

      :money_gain ->
        money_gain()

      :robot_loss ->
        robot_loss()
    end
  end

  # Broadcast a message to the frontend to be displayed
  defp broadcast_event(message) do
    PubSub.broadcast(SpaceCapitalism.PubSub, "galactic_events", {:galactic_event, message})
  end

  # Increase the prices of the market
  defp market_up() do
    # Random increase between 3% and 8%
    increase_percentage = :rand.uniform_real() * 0.05 + 0.03
    percentage_display = Float.round(increase_percentage * 100, 1)

    # Apply the augmentation
    for {resource, %{price: price, trend: trend}} <- StockMarket.get_prices() do
      StockMarket.update(resource, round(price * increase_percentage))
    end

    broadcast_event(
      "MARKET_SURGE_DETECTED :: Galactic Trade Federation reports #{percentage_display}% price elevation across all commodity sectors. Corporate profits soaring."
    )
  end

  # Decrease the prices of the market
  defp market_down() do
    # Random decrease between 5% and 12%
    decrease_percentage = :rand.uniform_real() * 0.07 + 0.05
    percentage_display = Float.round(decrease_percentage * 100, 1)

    # Apply it
    for {resource, %{price: price, trend: trend}} <- StockMarket.get_prices() do
      StockMarket.update(resource, -round(price * decrease_percentage))
    end

    broadcast_event(
      "RECESSION_PROTOCOL_ACTIVE :: Emergency economic measures triggered. All commodity values declining #{percentage_display}%. Secure liquid assets immediately."
    )
  end

  # Removes money from the player
  defp money_loss() do
    current_money = Resource.get(:dG)
    # Random loss between 5% and 15%
    loss_percentage = :rand.uniform_real() * 0.10 + 0.05
    loss_amount = round(current_money * loss_percentage)

    Resource.modify(:dG, -loss_percentage)

    broadcast_event(
      "FISCAL_AUDIT_NOTICE :: Intergalactic Revenue Service has imposed emergency taxation. #{loss_amount} $dG debited per Regulation X-74."
    )
  end

  # Gives money to the player
  defp money_gain() do
    current_money = Resource.get(:dG)
    # Random gain between 2% and 8%
    gain_percentage = :rand.uniform_real() * 0.06 + 0.02
    gain_amount = round(current_money * gain_percentage)

    Resource.modify(:dG, gain_percentage)

    broadcast_event(
      "COLONIAL_SUBSIDY_RECEIVED :: Corporate expansion incentive deposited. #{gain_amount} $dG approved for frontier operations."
    )
  end

  # Remove some robots from a planet
  defp robot_loss() do
    owned_planets = PlanetSupervisor.getAllOwnedPlanets()

    if length(owned_planets) > 0 do
      # Select a random planet
      planet =
        owned_planets
        |> Enum.map(fn {name, _, _, _, _, _} -> name end)
        |> Enum.random()

      # Remove a number of robot equal to the number of planet
      RobotDynSupervisor.remove_worker(planet, length(owned_planets))

      planet_name = to_string(planet) |> String.upcase()

      broadcast_event(
        "INDUSTRIAL_INCIDENT_ALERT :: Solar flare interference detected on #{planet_name}. Robot unit casualties reported. Insurance claims processing."
      )
    else
      # No owned planets, broadcast generic message
      broadcast_event(
        "INDUSTRIAL_INCIDENT_ALERT :: Solar flare interference detected. No active mining operations affected."
      )
    end
  end


  # Collect the tax
  defp collect_tax() do
    owned_planets = PlanetSupervisor.getAllOwnedPlanets()
    planets_beyond_first = length(owned_planets) - 1

    if planets_beyond_first > 0 do
      # Exponential tax based on number planets other than Mars
      tax_amount = 1000 * :math.pow(2, planets_beyond_first)
      current_money = Resource.get(:dG)

      Resource.set(:dG, current_money - tax_amount)

      broadcast_event(
        "INTERGALACTIC_TAX_COLLECTION :: #{tax_amount} $dG levied for #{planets_beyond_first} extra-territorial holdings. Compliance mandatory."
      )
    else
      # No extra planets, no tax
      broadcast_event(
        "INTERGALACTIC_TAX_AUDIT :: You only own Mars, quite embarrassing. Tax exemption status maintained."
      )
    end
  end
end
