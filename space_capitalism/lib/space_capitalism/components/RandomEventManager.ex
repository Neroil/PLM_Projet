defmodule RandomEventManager do
  use GenServer

  import StockMarket
  import Resource
  import RobotDynSupervisor
  import PlanetSupervisor

  alias Phoenix.PubSub

  def start_link(_) do
    events = [
       :market_up,
       :market_down,
       :money_loss,
       :money_gain,
       :robot_loss
    ]

    times = %{
      min: 10000,
      max: 60000
    }

    GenServer.start_link(__MODULE__, %{events: events, times: times}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Process.send_after(self(), :nextEvent, 30000)
    {:ok, state}
  end

  @impl true
  def handle_info(:nextEvent, state) do

    apply_event(Enum.random(state[:events]))


    Process.send_after(self(), :nextEvent, Enum.random(state[:times][:min]..state[:times][:max]))
    {:noreply, state}
  end
    defp apply_event(event) do
    IO.puts("#{event} is happening")

    case event do
      :market_up ->
        market_up()
        broadcast_event("MARKET_SURGE_DETECTED :: Galactic Trade Federation reports 5% price elevation across all commodity sectors. Corporate profits soaring.")

      :market_down ->
        market_down()
        broadcast_event("RECESSION_PROTOCOL_ACTIVE :: Emergency economic measures triggered. All commodity values declining 10%. Secure liquid assets immediately.")

      :money_loss ->
        money_loss()
        broadcast_event("FISCAL_AUDIT_NOTICE :: Intergalactic Revenue Service has imposed emergency taxation. Corporate accounts debited per Regulation X-74.")

      :money_gain ->
        money_gain()
        broadcast_event("COLONIAL_SUBSIDY_RECEIVED :: Corporate expansion incentive deposited. Galactic Commerce Ministry funding approved for frontier operations.")

      :robot_loss ->
        robot_loss()
        broadcast_event("INDUSTRIAL_INCIDENT_ALERT :: Solar flare interference detected. Robot unit casualties reported across mining operations. Insurance claims processing.")
    end
  end

  defp broadcast_event(message) do
    PubSub.broadcast(SpaceCapitalism.PubSub, "galactic_events", {:galactic_event, message})
  end

  defp market_up() do
    for {resource, %{price: price, trend: trend}} <- StockMarket.get_prices() do
      StockMarket.update(resource, round(price*0.05))
    end
  end

  defp market_down() do
    for {resource, %{price: price, trend: trend}} <- StockMarket.get_prices() do
      StockMarket.update(resource, -round(price*0.1))
    end
  end

  defp money_loss() do
    Resource.modify(:dG, -0.1)
  end

  defp money_gain() do
    Resource.modify(:dG, 0.05)
  end

  defp robot_loss() do
    planet = PlanetSupervisor.getAllOwnedPlanets()
      |> Enum.map(fn {name,_,_,_,_,_} -> name end)
      |> Enum.random()

    RobotDynSupervisor.remove_worker(planet, 1)
  end


end
