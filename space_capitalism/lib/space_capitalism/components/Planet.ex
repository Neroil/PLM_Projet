defmodule PlanetRegistry do
  @registry_name __MODULE__

  def start_link do
    Registry.start_link(keys: :unique, name: @registry_name)
  end

  def registry_name, do: @registry_name
end

defmodule Planet do
  use GenServer

  # Démarrer un Planet avec un nom et une ressource initiale
  def start_link({name, cost, resource, rbPrice, rbMaintenance, is_owned}) do
    IO.puts("Planet #{name}")
    {:ok, pid} = RobotDynSupervisor.start_link(name)

    GenServer.start_link(
      __MODULE__,
      %{
        resource: resource,
        cost: cost,
        robots: pid,
        name: name,
        robot_price: rbPrice,
        robot_maintenance: rbMaintenance,
        owned: is_owned
      },
      name: {:via, Registry, {PlanetRegistry, name}}
    )
  end

  @impl true
  def init(state) do
    IO.puts("Planet process started: #{state[:name]}")

    initial_state =
      Map.merge(state, %{
        robot_count: 0,
        production_rate: calculate_production_rate(state),
        level: 1
      })

    {:ok, initial_state}
  end

  # Calculate the production rate based on robot count and level
  defp calculate_production_rate(state) do
    base_rate = 10
    base_rate + (state[:robot_count] || 0) * (state[:level] || 1)
  end

  # Calculate the upgrade cost based on current level
  defp calculate_upgrade_cost(level) do
    base_cost = 500
    base_cost * level * level
  end

  defp via_tuple(name), do: {:via, Registry, {PlanetRegistry, name}}

  # Get the resource from the planet
  def get_resource(name) do
    IO.puts("Getting resource #{name}")
    GenServer.call(via_tuple(name), :get_resource)
  end

  # API functions
  def add_robot(name, count) do
    GenServer.cast(via_tuple(name), {:add_robot, count})
  end

  def get_robots(name) do
    IO.puts("Getting robots from #{name}")
    GenServer.call(via_tuple(name), :get_robots)
  end

  def get_robot_cost(name) do
    IO.puts("Getting robot cost from #{name}")
    GenServer.call(via_tuple(name), :get_robot_cost)
  end

  def get_production_rate(name) do
    GenServer.call(via_tuple(name), :get_production_rate)
  end

  def get_upgrade_cost(name) do
    GenServer.call(via_tuple(name), :get_upgrade_cost)
  end

  def get_owned(name) do
    GenServer.call(via_tuple(name), :get_owned)
  end

  def upgrade(name) do
    GenServer.cast(via_tuple(name), :upgrade)
  end

  def get_robots(name) do
    GenServer.call(via_tuple(name), :get_robots)
  end

  def get_cost(name) do
    GenServer.call(via_tuple(name), :get_cost)
  end

  def get_all_data(name) do
    GenServer.call(via_tuple(name), :get_all_data)
  end

  def buy_planet(name) do
    GenServer.cast(via_tuple(name), :buy_planet)
  end

  # GenServer callbacks
  @impl true
  def handle_call(:get_resource, _from, state) do
    IO.puts("Handling resource!")
    {:reply, state.resource, state}
  end

  @impl true
  def handle_call(:get_robots, _from, state) do
    {:reply, state.robot_count, state}
  end

  @impl true
  def handle_call(:get_robot_cost, _from, state) do
    {:reply, state[:robot_price], state}
  end

  @impl true
  def handle_call(:get_production_rate, _from, state) do
    {:reply, state.production_rate, state}
  end

  @impl true
  def handle_call(:get_upgrade_cost, _from, state) do
    cost = calculate_upgrade_cost(state.level)
    {:reply, cost, state}
  end

  @impl true
  def handle_call(:get_owned, _from, state) do
    {:reply, state.owned, state}
  end

  @impl true
  def handle_call(:get_cost, _from, state) do
    {:reply, state.cost, state}
  end

  @impl true
  def handle_cast(:buy_planet, state) do
    if !state.owned do
      case Resource.remove(:dG, state.cost) do
        {:ok, _} ->
          new_state = %{state | owned: true}
          {:noreply, new_state}

        {:error, _} ->
          IO.puts("Not enough money to buy planet #{state.name}")
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:add_robot, count}, state) do
    # Check if enough money
    case Resource.remove(:dG, count * state[:robot_price]) do
      {:ok, _} ->
        RobotDynSupervisor.add_worker(
          state[:name],
          count,
          state[:resource],
          state[:robot_maintenance]
        )

        new_state = %{state | robot_count: state.robot_count + count}
        new_state = %{new_state | production_rate: calculate_production_rate(new_state)}
        {:noreply, new_state}

      {:error, _} ->
        IO.puts("Not enough money")
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast(:upgrade, state) do
    # Implement upgrade logic with cost
    upgrade_cost = calculate_upgrade_cost(state.level)

    case Resource.remove(:dG, upgrade_cost) do
      {:ok, _} ->
        new_state = %{state | level: state.level + 1}
        # Update production rate after upgrading
        new_state = %{new_state | production_rate: calculate_production_rate(new_state)}
        {:noreply, new_state}

      {:error, _} ->
        IO.puts("Not enough money for upgrade")
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:get_all_data, _from, state) do
    # Calculate the upgrade cost based on current level
    upgrade_cost = calculate_upgrade_cost(state.level)

    data = %{
      robot_count: state.robot_count,
      cost: state.cost,
      production_rate: state.production_rate,
      robot_price: state[:robot_price],
      upgrade_cost: upgrade_cost,
      owned: state.owned,
      resource: state.resource,
      level: state.level
    }

    {:reply, data, state}
  end
end
