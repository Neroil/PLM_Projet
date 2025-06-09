defmodule SpaceCapitalismWeb.GameLive do
  use SpaceCapitalismWeb, :live_view
  alias Phoenix.PubSub

  import SpaceCapitalismWeb.GameComponents

  @impl true
  def mount(_params, _session, socket) do
    {owned_planets, available_planets} = fetch_and_format_planets()

    # Initialize game state
    socket =
      assign(socket,
        page_title: "Space Capitalism",
        resources: ResourceSupervisor.get_all_resources(),
        planets: owned_planets,
        # Market prices
        available_planets: available_planets,
        market: StockMarket.get_prices(),

        # Available technology upgrades - get from UpgradeManager
        available_upgrades:
          UpgradeManager.get_upgrades()
          |> Enum.map(fn {id, upgrade} ->
            Map.put(upgrade, :id, id)
          end)
          |> Enum.sort_by(& &1.cost, :asc),

        # Track purchased upgrades
        purchased_upgrades: [],

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

  def handle_info(:updateDisplayOnClick, socket) do
    updated_socket =
      socket
      |> assign(:resources, ResourceSupervisor.get_all_resources())
      # Update VM stats immediately on user actions
      |> assign(:vm_stats, get_vm_stats())
      |> update_planets_in_socket()

    {:noreply, updated_socket}
  end

  def handle_info(:updateDisplay, socket) do
    socket =
      socket
      |> assign(:resources, ResourceSupervisor.get_all_resources())
      |> assign(:market, StockMarket.get_prices())
      |> update_planets_in_socket()
      |> assign(:tax_countdown, EventManager.get_next_tax_countdown())

    {:noreply, socket}
  end

  @impl true
  def handle_event("sell_form_change", %{"quantity" => quantity, "resource" => resource}, socket) do
    handle_form_change(quantity, resource, socket, "sell")
  end

  @impl true
  def handle_event("buy_form_change", %{"quantity" => quantity, "resource" => resource}, socket) do
    handle_form_change(quantity, resource, socket, "buy")
  end

  @impl true
  def handle_event("toggle_vm_stats", _params, socket) do
    {:noreply, assign(socket, :vm_stats_minimized, !socket.assigns.vm_stats_minimized)}
  end

  # Add CPU stress test event handlers
  @impl true
  def handle_event("stress_test_light", _params, socket) do
    {process_count, _duration} = get_stress_test_config(:light)
    start_cpu_stress_test(:light)

    {:noreply,
     put_flash(
       socket,
       :info,
       "Light CPU stress test started (#{process_count} processes) - should increase run queue"
     )}
  end

  @impl true
  def handle_event("stress_test_medium", _params, socket) do
    {process_count, _duration} = get_stress_test_config(:medium)
    start_cpu_stress_test(:medium)

    {:noreply,
     put_flash(
       socket,
       :info,
       "Medium CPU stress test started (#{process_count} processes) - should saturate CPU"
     )}
  end

  @impl true
  def handle_event("stress_test_heavy", _params, socket) do
    {process_count, _duration} = get_stress_test_config(:heavy)
    start_cpu_stress_test(:heavy)

    {:noreply,
     put_flash(
       socket,
       :info,
       "Heavy CPU stress test started (#{process_count} processes) - should overload CPU"
     )}
  end

  @impl true
  def handle_event("stop_stress_test", _params, socket) do
    stop_cpu_stress_test()

    {:noreply,
     put_flash(socket, :info, "CPU stress test stopped - run queue should return to 0-1")}
  end

  def handle_event("buy_resource", %{"resource" => resource, "quantity" => quantity}, socket) do
    handle_resource_transaction(resource, quantity, socket, false)
  end

  def handle_event("sell_resource", %{"resource" => resource, "quantity" => quantity}, socket) do
    handle_resource_transaction(resource, quantity, socket, true)
  end

  @impl true
  def handle_event("buy_planet", %{"planet" => planet_name}, socket) do
    handle_action_with_update(PlanetSupervisor.buy_planet(planet_name), socket)
  end

  @impl true
  def handle_event("add_robot", %{"planet" => planet_id}, socket) do
    handle_action_with_update(Planet.add_robot(String.to_atom(planet_id), 1), socket)
  end

  # Upgrade events handler
  @impl true
  def handle_event("buy_upgrade", %{"upgrade" => upgrade_id}, socket) do
    case UpgradeManager.buy_upgrade(upgrade_id) do
      {:ok, message} ->
        # Remove the purchased upgrade from available list
        updated_available_upgrades =
          Enum.filter(socket.assigns.available_upgrades, fn upgrade ->
            upgrade.id != upgrade_id
          end)

        # Add to purchased upgrades list
        updated_purchased_upgrades = [upgrade_id | socket.assigns.purchased_upgrades]

        # Update the planets list and upgrade state
        send(self(), :updateDisplayOnClick)

        socket
        |> assign(:available_upgrades, updated_available_upgrades)
        |> assign(:purchased_upgrades, updated_purchased_upgrades)
        |> put_flash(:info, message)
        |> then(&{:noreply, &1})

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}

      # Fallback for any other response format
      _ ->
        {:noreply, socket}
    end
  end

  # Private function to handle both buying and selling resources
  # Validates input, performs transaction, and updates UI with appropriate flash messages
  # Parameters:
  # - resource: string name of the resource
  # - quantity: string quantity to trade
  # - socket: LiveView socket
  # - is_selling: boolean indicating if this is a sell (true) or buy (false) operation
  defp handle_resource_transaction(resource, quantity, socket, is_selling) do
    if resource == "" or quantity == "" do
      {:noreply, put_flash(socket, :error, "Resource and quantity must not be empty")}
    else
      try do
        quantity_int = String.to_integer(quantity)

        if quantity_int <= 0 do
          {:noreply, put_flash(socket, :error, "Quantity must be greater than 0")}
        else
          # Perform the transaction
          result =
            if is_selling do
              StockMarket.sell(String.to_atom(resource), quantity_int)
            else
              StockMarket.buy(String.to_atom(resource), quantity_int)
            end

          case result do
            {:ok, message} ->
              # Clear the appropriate form value after successful transaction
              form_type = if is_selling, do: "sell", else: "buy"
              form_key = "#{resource}_#{form_type}_quantity"
              new_form_values = Map.delete(socket.assigns.form_values, form_key)

              socket
              |> assign(:form_values, new_form_values)
              |> put_flash(:info, message)
              |> then(&{:noreply, &1})

            {:error, error_message} ->
              {:noreply, put_flash(socket, :error, error_message)}

            _ ->
              {:noreply, put_flash(socket, :error, "Transaction failed due to unknown error")}
          end
        end
      rescue
        ArgumentError ->
          {:noreply, put_flash(socket, :error, "Invalid quantity format")}
      end
    end
  end

  # Format large numbers for display (converts to K/M notation for readability)
  defp format_number(number) when is_integer(number) do
    cond do
      number >= 1_000_000 -> "#{div(number, 1_000_000)}M"
      number >= 1_000 -> "#{div(number, 1_000)}K"
      true -> "#{number}"
    end
  end

  # Handle floats by rounding to integer first
  defp format_number(number) when is_float(number) do
    number = round(number)
    format_number(number)
  end

  # Handle values that are already strings (pass through)
  defp format_number(number) when is_binary(number) do
    number
  end

  # Fallback for any other types
  defp format_number(_) do
    "N/A"
  end

  # Format countdown timer in MM:SS format
  defp format_countdown(seconds) when is_integer(seconds) and seconds >= 0 do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)

    "#{String.pad_leading("#{minutes}", 2, "0")}:#{String.pad_leading("#{remaining_seconds}", 2, "0")}"
  end

  defp format_countdown(_), do: "00:00"
  # Collect comprehensive BEAM VM statistics for system monitoring
  # Returns a map with process counts, memory usage, scheduler info, and performance metrics
  # Used for the real-time system monitor display in the game UI
  defp get_vm_stats do
    concurrent_stats = get_concurrent_game_stats()

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
      # Game-specific concurrent process stats
      io_activity: :erlang.statistics(:io) |> elem(0) |> elem(0) |> format_number(),
      game_processes: concurrent_stats.game_processes,
      active_planets: concurrent_stats.active_planets,
      robot_workers: concurrent_stats.robot_workers,
      resource_agents: concurrent_stats.resource_agents,
      supervisor_tree: concurrent_stats.supervisor_tree,
      concurrent_operations: concurrent_stats.concurrent_operations,
      # Add stress test info
      stress_test_info: concurrent_stats.stress_test_info,
      stress_test_preview: get_stress_test_preview()
    }
  end

  # Get detailed statistics about concurrent game processes
  # This showcases the concurrent nature of the application
  defp get_concurrent_game_stats do
    # Count game-specific processes
    planet_processes = count_planet_processes()
    robot_processes = count_robot_processes()
    resource_processes = count_resource_processes()

    # Calculate concurrent operations happening right now
    concurrent_ops = calculate_concurrent_operations()

    %{
      # +4 for StockMarket, EventManager, etc.
      game_processes: planet_processes + robot_processes + resource_processes + 4,
      active_planets: planet_processes,
      robot_workers: robot_processes,
      resource_agents: resource_processes,
      supervisor_tree: count_supervisors(),
      concurrent_operations: concurrent_ops,
      # Add stress test info
      stress_test_info: get_current_stress_test_info()
    }
  end

  # Count planet GenServer processes
  defp count_planet_processes do
    try do
      # Get all planets with their current state and filter by actual ownership
      PlanetSupervisor.get_all_planets()
      |> Map.values()
      |> Enum.filter(fn planet -> planet.owned end)
      |> length()
    rescue
      _ -> 0
    end
  end

  # Count robot worker processes across all planets
  defp count_robot_processes do
    try do
      # Get all planets with their current state and filter by actual ownership
      owned_planets =
        PlanetSupervisor.get_all_planets()
        |> Map.values()
        |> Enum.filter(fn planet -> planet.owned end)

      robot_counts =
        owned_planets
        |> Enum.map(fn planet ->
          try do
            children = DynamicSupervisor.which_children(planet.id)
            length(children)
          rescue
            _error ->
              0
          end
        end)

      Enum.sum(robot_counts)
    rescue
      _error ->
        0
    end
  end

  # Count resource Agent processes
  defp count_resource_processes do
    try do
      ResourceSupervisor.get_resources()
      |> length()
    rescue
      _ -> 0
    end
  end

  # Count supervisor processes in the game
  defp count_supervisors do
    try do
      # GameSupervisor, PlanetSupervisor, ResourceSupervisor + dynamic supervisors for each owned planet
      base_supervisors = 3

      owned_planet_count =
        PlanetSupervisor.get_all_planets()
        |> Map.values()
        |> Enum.filter(fn planet -> planet.owned end)
        |> length()

      base_supervisors + owned_planet_count
    rescue
      _ -> 3
    end
  end

  # Calculate how many concurrent operations might be happening
  defp calculate_concurrent_operations do
    try do
      # Estimate based on message queue lengths and process activity
      process_with_messages =
        Process.list()
        |> Enum.count(fn pid ->
          case Process.info(pid, :message_queue_len) do
            {:message_queue_len, len} when len > 0 -> true
            _ -> false
          end
        end)

    rescue
      _ -> 0
    end
  end

  # Calculate the current BEAM VM reductions per second
  # Tracks execution performance by measuring reduction differences over time
  # Uses process dictionary to store previous measurements for delta calculation
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

  # Fetch and format planet data for UI display
  # Returns a tuple of {owned_planets, available_planets} with formatted data structures
  # Separates planets based on ownership status for different UI sections
  defp fetch_and_format_planets do
    all_planets = PlanetSupervisor.get_all_planets()
    planets_list = Map.values(all_planets)

    owned_planets = format_owned_planets(planets_list)
    available_planets = format_available_planets(planets_list)

    {owned_planets, available_planets}
  end

  # Filter and format owned planets for the planet management UI
  # Includes production statistics, robot counts, and upgrade costs
  defp format_owned_planets(planets_list) do
    planets_list
    |> Enum.filter(fn planet -> planet.owned end)
    |> Enum.map(&format_owned_planet/1)
  end

  # Filter and format available planets for the colonization UI
  # Shows basic planet info and purchase costs for unowned planets
  defp format_available_planets(planets_list) do
    planets_list
    |> Enum.filter(fn planet -> !planet.owned end)
    |> Enum.map(&format_available_planet/1)
    |> Enum.sort_by(& &1.cost, :asc)
  end

  # Format owned planet data for UI display
  # Includes operational statistics like robot count, production rate, and costs
  defp format_owned_planet(planet) do
    %{
      id: planet.id,
      name: planet.name,
      resource_type: planet.resource_type,
      robots: planet.robots,
      production_rate: planet.production_rate,
      robot_cost: planet.robot_cost,
      upgrade_cost: planet.upgrade_cost
    }
  end

  # Format available planet data for colonization UI
  # Shows essential info needed for purchase decisions: name, resource type, and cost
  defp format_available_planet(planet) do
    %{
      id: planet.id,
      name: planet.name,
      resource_type: planet.resource_type,
      cost: planet.cost
    }
  end

  # Update planet data in the LiveView socket
  # Refreshes both owned and available planets lists for UI consistency
  defp update_planets_in_socket(socket) do
    {owned_planets, available_planets} = fetch_and_format_planets()

    socket
    |> assign(:planets, owned_planets)
    |> assign(:available_planets, available_planets)
  end

  # Handle form input changes for resource trading
  # Maintains form state across re-renders by storing values in socket assigns
  # Parameters: quantity, resource name, socket, form_type ("buy" or "sell")
  defp handle_form_change(quantity, resource, socket, form_type) do
    form_key = "#{resource}_#{form_type}_quantity"
    new_form_values = Map.put(socket.assigns.form_values, form_key, quantity)
    {:noreply, assign(socket, :form_values, new_form_values)}
  end

  # Handle action results with automatic UI updates and flash messages
  # Standardizes error/success handling for game actions like buying planets or resources
  # Parameters:
  # - action_result: tuple {:ok, message} or {:error, reason}
  # - socket: LiveView socket
  # - success_message_override: optional custom success message
  defp handle_action_with_update(action_result, socket, success_message_override \\ nil) do
    case action_result do
      {:ok, message} ->
        final_message = success_message_override || message
        send(self(), :updateDisplayOnClick)
        {:noreply, put_flash(socket, :info, final_message)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}

      _ ->
        {:noreply, socket}
    end
  end

  # CPU stress testing functions to artificially increase run queue
  defp start_cpu_stress_test(intensity) do
    # Stop any existing stress test first
    stop_cpu_stress_test()

    {process_count, duration} = get_stress_test_config(intensity)

    # Store the PIDs in the process dictionary for cleanup
    stress_pids =
      Enum.map(1..process_count, fn _i ->
        spawn(fn -> cpu_intensive_work(duration) end)
      end)

    Process.put(:stress_test_pids, stress_pids)

    # Auto-cleanup after duration
    Process.send_after(self(), :auto_stop_stress_test, duration + 1000)
  end

  # Get stress test configuration based on CPU cores
  defp get_stress_test_config(intensity) do
    scheduler_count = :erlang.system_info(:schedulers_online)

    case intensity do
      :light ->
        # Use 1/2 of available schedulers, 10 seconds
        process_count = max(2, div(scheduler_count, 2))
        {process_count, 10_000}

      :medium ->
        # Use same number as schedulers (100% CPU), 12 seconds
        {scheduler_count, 12_000}

      :heavy ->
        # Use 2x schedulers (200% CPU load), 15 seconds
        process_count = scheduler_count * 2
        {process_count, 15_000}

      _ ->
        # Fallback
        {max(2, div(scheduler_count, 2)), 10_000}
    end
  end

  defp stop_cpu_stress_test do
    case Process.get(:stress_test_pids) do
      nil ->
        :ok

      pids when is_list(pids) ->
        Enum.each(pids, fn pid ->
          if Process.alive?(pid) do
            Process.exit(pid, :kill)
          end
        end)

        Process.delete(:stress_test_pids)

      _ ->
        :ok
    end
  end

  # CPU-intensive work that will compete for scheduler time
  defp cpu_intensive_work(duration_ms) do
    start_time = :erlang.monotonic_time(:millisecond)
    end_time = start_time + duration_ms

    cpu_loop(end_time)
  end

  defp cpu_loop(end_time) do
    current_time = :erlang.monotonic_time(:millisecond)
    # Do some CPU-intensive work
    if current_time < end_time do
      # Calculate prime numbers, factorial, or other math operations
      _result =
        Enum.reduce(1..1000, 0, fn i, acc ->
          acc + round(:math.pow(i, 2)) + round(:math.sqrt(i))
        end)

      # Continue the loop
      cpu_loop(end_time)
    end
  end

  @impl true
  def handle_info(:auto_stop_stress_test, socket) do
    stop_cpu_stress_test()
    {:noreply, put_flash(socket, :info, "CPU stress test automatically stopped")}
  end

  # Get information about currently running stress test
  defp get_current_stress_test_info do
    case Process.get(:stress_test_pids) do
      nil ->
        %{active: false, process_count: 0}

      pids when is_list(pids) ->
        alive_count = Enum.count(pids, &Process.alive?/1)
        %{active: alive_count > 0, process_count: alive_count}

      _ ->
        %{active: false, process_count: 0}
    end
  end

  # Add a helper function to get stress test preview info
  def get_stress_test_preview do
    scheduler_count = :erlang.system_info(:schedulers_online)

    %{
      light: max(2, div(scheduler_count, 2)),
      medium: scheduler_count,
      heavy: scheduler_count * 2,
      schedulers: scheduler_count
    }
  end
end
