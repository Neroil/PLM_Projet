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
        resources: ResourceSupervisor.getAllResources(),
        planets: owned_planets,
        # Market prices
        available_planets: available_planets,
        market: StockMarket.get_prices(),

        # Available technology upgrades - get from UpgradeManager
        available_upgrades:
          UpgradeManager.getUpgrades()
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
    updated_socket =
      socket
      |> assign(:resources, ResourceSupervisor.getAllResources())
      |> update_planets_in_socket()

    {:noreply, updated_socket}
  end

  def handle_info(:updateDisplay, socket) do
    socket =
      socket
      |> assign(:resources, ResourceSupervisor.getAllResources())
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

  def handle_event("buy_resource", %{"resource" => resource, "quantity" => quantity}, socket) do
    handle_resource_transaction(resource, quantity, socket, false)
  end

  def handle_event("sell_resource", %{"resource" => resource, "quantity" => quantity}, socket) do
    handle_resource_transaction(resource, quantity, socket, true)
  end

  # Private function to handle both buying and selling resources
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

  @impl true
  def handle_event("buy_planet", %{"planet" => planet_name}, socket) do
    handle_action_with_update(PlanetSupervisor.buyPlanet(planet_name), socket)
  end

  @impl true
  def handle_event("add_robot", %{"planet" => planet_id}, socket) do
    handle_action_with_update(Planet.add_robot(String.to_atom(planet_id), 1), socket)
  end

  # Upgrade events handler
  @impl true
  def handle_event("buy_upgrade", %{"upgrade" => upgrade_id}, socket) do
    case UpgradeManager.buyUpgrade(upgrade_id) do
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

  # Helper functions for planet management
  defp fetch_and_format_planets do
    all_planets = PlanetSupervisor.getAllPlanets()
    planets_list = Map.values(all_planets)

    owned_planets = format_owned_planets(planets_list)
    available_planets = format_available_planets(planets_list)

    {owned_planets, available_planets}
  end

  defp format_owned_planets(planets_list) do
    planets_list
    |> Enum.filter(fn planet -> planet.owned end)
    |> Enum.map(&format_owned_planet/1)
  end

  defp format_available_planets(planets_list) do
    planets_list
    |> Enum.filter(fn planet -> !planet.owned end)
    |> Enum.map(&format_available_planet/1)
    |> Enum.sort_by(& &1.cost, :asc)
  end

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

  defp format_available_planet(planet) do
    %{
      id: planet.id,
      name: planet.name,
      resource_type: planet.resource_type,
      cost: planet.cost
    }
  end

  defp update_planets_in_socket(socket) do
    {owned_planets, available_planets} = fetch_and_format_planets()

    socket
    |> assign(:planets, owned_planets)
    |> assign(:available_planets, available_planets)
  end

  defp handle_form_change(quantity, resource, socket, form_type) do
    form_key = "#{resource}_#{form_type}_quantity"
    new_form_values = Map.put(socket.assigns.form_values, form_key, quantity)
    {:noreply, assign(socket, :form_values, new_form_values)}
  end

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

  # Utility functions for upgrade management
  defp get_upgrade_info(upgrade_id) do
    UpgradeManager.getUpgrade(upgrade_id)
  end

  defp is_upgrade_available?(upgrade_id, purchased_upgrades) do
    !Enum.member?(purchased_upgrades, upgrade_id)
  end

  defp can_afford_upgrade?(upgrade_id) do
    case get_upgrade_info(upgrade_id) do
      nil -> false
      upgrade -> Resource.get(:dG) >= upgrade.cost
    end
  end
end
