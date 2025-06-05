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
        tax_timer: 5,
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
          %{message: "Your first tax payment will be due in 5 minutes."}
        ]
      )

    # Start timers for production and events
    # if connected?(socket) do
    #   # Production timer - every second
    #   :timer.send_interval(1000, self(), :tick_production)

    #   # Market update timer - every 30 seconds
    #   :timer.send_interval(30000, self(), :update_market)

    #   # Event timer - random event every 2 minutes
    #   :timer.send_interval(120000, self(), :random_event)

    #   # Tax timer - every 5 minutes
    #   :timer.send_interval(300000, self(), :collect_taxes)

    #   # Subscribe to game events
    #   PubSub.subscribe(SpaceCapitalism.PubSub, "game_events")
    # end

    # Start the function to update display
    :timer.send_interval(200, self(), :updateDisplay)

    {:ok, socket}
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
    # Update resources
    socket =
      socket
      |> assign(:resources, ResourceSupervisor.getAllResources())

    # Return the updated socket
    {:noreply, socket}
  end

def handle_event("sell_resource", %{"resource" => resource, "quantity" => quantity}, socket) do
  if resource == "" or quantity == "" do
    IO.puts("Must not ne empty")
    {:noreply, socket}
  else
    StockMarket.sell(String.to_atom(resource), String.to_integer(quantity))
    {:noreply, socket}
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
