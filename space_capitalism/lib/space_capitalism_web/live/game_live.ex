defmodule SpaceCapitalismWeb.GameLive do
  use SpaceCapitalismWeb, :live_view
  alias Phoenix.PubSub

  import SpaceCapitalismWeb.GameComponents
  import ResourceSupervisor
  import StockMarket

  @impl true
  def mount(_params, _session, socket) do
    all_planets = PlanetSupervisor.getAllPlanets()

    owned_planets =
      all_planets
      |> Map.values()
      |> Enum.filter(fn planet -> planet.owned end)
      |> Enum.map(fn planet ->
        # Format the planet for display
        %{
          id: planet.id,
          name: planet.name,
          resource_type: planet.resource_type,
          robots: planet.robots,
          production_rate: planet.production_rate,
          robot_cost: planet.robot_cost,
          upgrade_cost: planet.upgrade_cost
        }
      end)

    available_planets =
      all_planets
      |> Map.values()
      |> Enum.filter(fn planet -> !planet.owned end)
      |> Enum.map(fn planet ->
        # Format available planets for display
        %{
          id: planet.id,
          name: planet.name,
          resource_type: planet.resource_type,
          cost: planet.cost
        }
      end)

    # Initialize game state
    socket =
      assign(socket,
        page_title: "Space Capitalism",
        resources: ResourceSupervisor.getAllResources(),
        planets: owned_planets,
        available_planets: available_planets,

        # Market prices
        market: StockMarket.get_prices(),

        # Available technology upgrades
        available_upgrades: [
          %{
            id: "iron_boost",
            name: "Iron Harvesting Boost",
            description: "Increase iron production by 25%",
            cost: 3000
          },
          %{
            id: "gold_boost",
            name: "Gold Mining Boost",
            description: "Increase gold production by 25%",
            cost: 5000
          },
          %{
            id: "uranium_boost",
            name: "Uranium Extraction Boost",
            description: "Increase uranium production by 25%",
            cost: 7500
          }
        ],

        # Recent events
        events: [
          %{message: "Welcome to Space Capitalism! You start with 10,000 $dG and 500 iron."},
          %{
            message:
              "Intergalactic Tax Authority enabled. Auto-collection from extra-territorial holdings every 5 minutes."
          }
        ],

        # Process monitoring
        process_count: Process.list() |> length(),
        # MB
        memory_usage: :erlang.memory() |> Keyword.get(:total) |> div(1024 * 1024),
        vm_stats: get_vm_stats(),
        # Form state to persist input values across re-renders
        vm_stats_minimized: false,
        form_values: %{},

        # Tax countdown timer
        tax_countdown: EventManager.get_next_tax_countdown()
      )

    # Start the function to update display
    # Enable scheduler utilization tracking
    :timer.send_interval(200, self(), :updateDisplay)
    :erlang.system_flag(:scheduler_wall_time, true)

    # Start VM stats update timer
    :timer.send_interval(1000, self(), :update_vm_stats)

    # Subscribe to galactic events
    PubSub.subscribe(SpaceCapitalism.PubSub, "galactic_events")

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_vm_stats, socket) do
    # Update VM stats
    updated_stats = get_vm_stats()

    # Assign the updated stats to the socket
    {:noreply, assign(socket, :vm_stats, updated_stats)}
  end

  @impl true
  def handle_info({:galactic_event, event_message}, socket) do
    # Get current timestamp in galactic format
    timestamp = DateTime.utc_now() |> DateTime.to_time() |> Time.to_string() |> String.slice(0, 8)

    # Add the new event to the events list with timestamp, keeping only the latest 5
    new_events =
      [
        %{
          message: event_message,
          timestamp: timestamp
        }
        | socket.assigns.events
      ]
      |> Enum.take(5)

    {:noreply, assign(socket, :events, new_events)}
  end

  defp format_number(number) when is_integer(number) do
    cond do
      number >= 1_000_000 -> "#{div(number, 1_000_000)}M"
      number >= 1_000 -> "#{div(number, 1_000)}K"
      true -> "#{number}"
    end
  end

  # Handle floats
  defp format_number(number) when is_float(number) do
    number = round(number)
    format_number(number)
  end

  # Handle values that are already strings
  defp format_number(number) when is_binary(number) do
    number
  end

  # Fallback for any other types
  defp format_number(_) do
    "N/A"
  end

  defp format_countdown(seconds) when is_integer(seconds) and seconds >= 0 do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)

    "#{String.pad_leading("#{minutes}", 2, "0")}:#{String.pad_leading("#{remaining_seconds}", 2, "0")}"
  end

  defp format_countdown(_), do: "00:00"

  defp get_vm_stats do
    %{
      process_count: Process.list() |> length(),
      process_limit: :erlang.system_info(:process_limit) |> format_number(),
      # MB
      memory_usage: "#{:erlang.memory() |> Keyword.get(:total) |> div(1024 * 1024)} MB",
      reduction_count: :erlang.statistics(:reductions) |> elem(0) |> format_number(),
      run_queue: :erlang.statistics(:run_queue),
      # More reliable activity indicators
      reductions_per_second: get_reductions_per_second() |> format_number(),
      # Number of schedulers (OS threads)
      scheduler_count: :erlang.system_info(:schedulers_online),
      atom_count: :erlang.system_info(:atom_count) |> format_number(),
      # Garbage collection info
      gc_count: :erlang.statistics(:garbage_collection) |> elem(0) |> format_number(),
      # Message queue activity
      io_activity: :erlang.statistics(:io) |> elem(0) |> elem(0) |> format_number()
    }
  end

  defp get_reductions_per_second do
    current_time = :erlang.monotonic_time(:millisecond)
    {current_reductions, _} = :erlang.statistics(:reductions)

    # Store previous values
    {prev_reductions, prev_time} =
      Process.get(:prev_reductions_stats, {current_reductions, current_time})

    Process.put(:prev_reductions_stats, {current_reductions, current_time})

    # Calculate reductions per second
    time_diff = current_time - prev_time
    reduction_diff = current_reductions - prev_reductions

    if time_diff > 0 do
      reductions_per_ms = reduction_diff / time_diff
      reductions_per_second = reductions_per_ms * 1000
      round(reductions_per_second)
    else
      0
    end
  end

  def handle_info(:updateDisplayOnClick, socket) do
    # Get all planets from the supervisor
    all_planets = PlanetSupervisor.getAllPlanets()

    # Update owned planets
    owned_planets =
      all_planets
      |> Map.values()
      |> Enum.filter(fn planet -> planet.owned end)
      |> Enum.map(fn planet ->
        %{
          id: planet.id,
          name: planet.name,
          resource_type: planet.resource_type,
          robots: planet.robots,
          production_rate: planet.production_rate,
          robot_cost: planet.robot_cost,
          upgrade_cost: planet.upgrade_cost
        }
      end)

    # Update non owned planets
    available_planets =
      all_planets
      |> Map.values()
      |> Enum.filter(fn planet -> !planet.owned end)
      |> Enum.map(fn planet ->
        %{
          id: planet.id,
          name: planet.name,
          resource_type: planet.resource_type,
          cost: planet.cost
        }
      end)

    # Update resources and assign to socket
    updated_socket =
      socket
      |> assign(:resources, ResourceSupervisor.getAllResources())
      |> assign(:planets, owned_planets)
      |> assign(:available_planets, available_planets)

    # Return the updated socket
    {:noreply, updated_socket}
  end

  def handle_info(:updateDisplay, socket) do
    # Update resources and market data
    socket =
      socket
      |> assign(:resources, ResourceSupervisor.getAllResources())
      |> assign(:market, StockMarket.get_prices())

    # Also update planet data to reflect backend state changes (e.g., from random events)
    all_planets = PlanetSupervisor.getAllPlanets()

    # Update owned planets
    owned_planets =
      all_planets
      |> Map.values()
      |> Enum.filter(fn planet -> planet.owned end)
      |> Enum.map(fn planet ->
        %{
          id: planet.id,
          name: planet.name,
          resource_type: planet.resource_type,
          robots: planet.robots,
          production_rate: planet.production_rate,
          robot_cost: planet.robot_cost,
          upgrade_cost: planet.upgrade_cost
        }
      end)

    # Update available planets
    available_planets =
      all_planets
      |> Map.values()
      |> Enum.filter(fn planet -> !planet.owned end)
      |> Enum.map(fn planet ->
        %{
          id: planet.id,
          name: planet.name,
          resource_type: planet.resource_type,
          cost: planet.cost
        }
      end)

    socket =
      socket
      |> assign(:planets, owned_planets)
      |> assign(:available_planets, available_planets)
      |> assign(:tax_countdown, EventManager.get_next_tax_countdown())

    {:noreply, socket}
  end

  @impl true
  def handle_event("sell_form_change", %{"quantity" => quantity, "resource" => resource}, socket) do
    # Store the sell form value in socket state
    form_key = "#{resource}_sell_quantity"
    new_form_values = Map.put(socket.assigns.form_values, form_key, quantity)

    {:noreply, assign(socket, :form_values, new_form_values)}
  end

  @impl true
  def handle_event("buy_form_change", %{"quantity" => quantity, "resource" => resource}, socket) do
    # Store the buy form value in socket state
    form_key = "#{resource}_buy_quantity"
    new_form_values = Map.put(socket.assigns.form_values, form_key, quantity)

    {:noreply, assign(socket, :form_values, new_form_values)}
  end

  @impl true
  def handle_event("toggle_vm_stats", _params, socket) do
    {:noreply, assign(socket, :vm_stats_minimized, !socket.assigns.vm_stats_minimized)}
  end

  def handle_event("buy_resource", %{"resource" => resource, "quantity" => quantity}, socket) do
    handle_resource_transaction(resource, quantity, socket, false)
  end

  def handle_event("sell_resource", %{"resource" => resource, "quantity" => quantity}, socket) do
    handle_resource_transaction(resource, quantity, socket, true)
  end

  # Private function to handle both buying and selling resources
  defp handle_resource_transaction(resource, quantity, socket, is_selling) do
    if resource == "" or quantity == "" do
      IO.puts("Must not be empty")
      {:noreply, socket}
    else
      # Perform the transaction
      if is_selling do
        StockMarket.sell(String.to_atom(resource), String.to_integer(quantity))
      else
        StockMarket.buy(String.to_atom(resource), String.to_integer(quantity))
      end

      # Clear the appropriate form value after successful transaction
      form_type = if is_selling, do: "sell", else: "buy"
      form_key = "#{resource}_#{form_type}_quantity"
      new_form_values = Map.delete(socket.assigns.form_values, form_key)

      {:noreply, assign(socket, :form_values, new_form_values)}
    end
  end

  @impl true
  def handle_event("buy_planet", %{"planet" => planet_name}, socket) do
    case PlanetSupervisor.buyPlanet(planet_name) do
      {:ok, message} ->
        # Update the planets list
        send(self(), :updateDisplayOnClick)
        {:noreply, put_flash(socket, :info, message)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}

      # Fallback for any other response format
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("upgrade_planet", %{"planet" => planet_id}, socket) do
    val = Resource.get(:iron)
    IO.puts("#{val} iron")
    {:noreply, socket}
  end

  # Handle events from UI
  @impl true
  def handle_event("add_robot", %{"planet" => planet_id}, socket) do
    Planet.add_robot(String.to_atom(planet_id), 1)
    send(self(), :updateDisplayOnClick)

    {:noreply, socket}
  end

  @doc """
  @impl true
  def handle_event("buy_planet", %{"planet" => planet_id}, socket) do
    # Find the planet to buy
    planet = Enum.find(socket.assigns.available_planets, &(&1.id == planet_id))

    if planet do
      # Check if player can afford the planet
      if socket.assigns.resources.money >= planet.cost do
        # Update money
        new_resources = Map.update!(socket.assigns.resources, :money, &(&1 - planet.cost))

        # Add planet to owned planets with initial settings
        new_planet = Map.merge(planet, %{
          robots: 0,
          production_rate: 0,
          robot_cost: 500,
          upgrade_cost: 2000
        })

        new_planets = [new_planet | socket.assigns.planets]

        # Remove from available planets
        new_available = Enum.reject(socket.assigns.available_planets, &(&1.id == planet_id))

        # Add event
        new_events = [%{message: "Purchased planet # {planet.name}!"} | socket.assigns.events] |> Enum.take(5)

        socket = socket
          |> assign(:resources, new_resources)
          |> assign(:planets, new_planets)
          |> assign(:available_planets, new_available)
          |> assign(:events, new_events)

        {:noreply, socket}
      else
        {:noreply, put_flash(socket, :error, "Not enough money to buy planet!")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("sell_resource", %{"resource" => resource}, socket) do
    # Get the amount from the form (would need to be implemented properly)
    # This is a placeholder - in a real implementation, you would get this from the params
    amount = 10  # Example amount

    resource_key = String.downcase(resource) |> String.to_atom()
    market_data = socket.assigns.market[resource]

    # Check if player has enough resources
    if Map.get(socket.assigns.resources, resource_key, 0) >= amount do
      # Calculate sale value
      sale_value = amount * market_data.price

      # Update resources
      new_resources =
        socket.assigns.resources
        |> Map.update!(resource_key, &(&1 - amount))
        |> Map.update!(:money, &(&1 + sale_value))

      # Add event
      new_events = [%{message: "Sold # {amount} # {resource} for # {sale_value} $dG."} | socket.assigns.events] |> Enum.take(5)

      socket = socket
        |> assign(:resources, new_resources)
        |> assign(:events, new_events)

      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "Not enough # {resource} to sell!")}
    end
  end

  @impl true
  def handle_event("buy_resource", %{"resource" => resource}, socket) do
    # Get the amount from the form (would need to be implemented properly)
    # This is a placeholder - in a real implementation, you would get this from the params
    amount = 10  # Example amount

    resource_key = String.downcase(resource) |> String.to_atom()
    market_data = socket.assigns.market[resource]

    # Calculate purchase cost
    purchase_cost = amount * market_data.price

    # Check if player has enough money
    if socket.assigns.resources.money >= purchase_cost do
      # Update resources
      new_resources =
        socket.assigns.resources
        |> Map.update!(resource_key, &(&1 + amount))
        |> Map.update!(:money, &(&1 - purchase_cost))

      # Add event
      new_events = [%{message: "Bought # {amount} # {resource} for # {purchase_cost} $dG."} | socket.assigns.events] |> Enum.take(5)

      socket = socket
        |> assign(:resources, new_resources)
        |> assign(:events, new_events)

      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "Not enough money to buy # {resource}!")}
    end
  end

  @impl true
  def handle_event("buy_upgrade", %{"upgrade" => upgrade_id}, socket) do
    # Find the upgrade
    upgrade = Enum.find(socket.assigns.available_upgrades, &(&1.id == upgrade_id))

    if upgrade do
      # Check if player can afford the upgrade
      if socket.assigns.resources.money >= upgrade.cost do
        # Update money
        new_resources = Map.update!(socket.assigns.resources, :money, &(&1 - upgrade.cost))

        # Remove upgrade from available list
        new_upgrades = Enum.reject(socket.assigns.available_upgrades, &(&1.id == upgrade_id))

        # Apply upgrade effect (simplified example)
        socket =
          case upgrade.id do
            "iron_boost" ->
              # Increase iron production by 25% on all iron planets
              new_planets = Enum.map(socket.assigns.planets, fn planet ->
                if planet.resource_type == "Iron (Fe)" do
                  Map.update!(planet, :production_rate, &(&1 * 1.25))
                else
                  planet
                end
              end)
              assign(socket, :planets, new_planets)

            "gold_boost" ->
              # Increase gold production by 25% on all gold planets
              new_planets = Enum.map(socket.assigns.planets, fn planet ->
                if planet.resource_type == "Gold (Or)" do
                  Map.update!(planet, :production_rate, &(&1 * 1.25))
                else
                  planet
                end
              end)
              assign(socket, :planets, new_planets)

            "uranium_boost" ->
              # Increase uranium production by 25% on all uranium planets
              new_planets = Enum.map(socket.assigns.planets, fn planet ->
                if planet.resource_type == "Uranium (Ur)" do
                  Map.update!(planet, :production_rate, &(&1 * 1.25))
                else
                  planet
                end
              end)
              assign(socket, :planets, new_planets)

            _ -> socket
          end

        # Add event
        new_events = [%{message: "Purchased upgrade: # {upgrade.name}!"} | socket.assigns.events] |> Enum.take(5)

        socket = socket
          |> assign(:resources, new_resources)
          |> assign(:available_upgrades, new_upgrades)
          |> assign(:events, new_events)

        {:noreply, socket}
      else
        {:noreply, put_flash(socket, :error, "Not enough money to buy upgrade!")}
      end
    else
      {:noreply, socket}
    end
  end
  """
end
