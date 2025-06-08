defmodule PlanetRegistry do
  @moduledoc """
    This module help to register each Planet GenServer
    with a specific name
  """

  @registry_name __MODULE__

  def start_link do
    Registry.start_link(keys: :unique, name: @registry_name)
  end

  def registry_name, do: @registry_name
end

defmodule Planet do
  use GenServer

  @moduledoc """
    This module represent an in-game planet.
  """

  @doc """
  Start the planet genserver

  ## Parameter
  A tuple containing :
  - name: `atom` Name of the planet
  - cost: `integer` Cost to buy the planet
  - resource: `atom` Resource produced by the planet
  - rbPrice: `integer` Price to add a robot on the planet
  - rbMaintenance: `integer` Cost of maintenance of a robot
  - is_owned: `boolean` Define if the player owns the planet or not
  """
  def start_link({name, cost, resource, rbPrice, rbMaintenance, is_owned}) do
    # Start the supervisor to handle robot on this planet
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

    # Add informations to the base state
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

  # Get the Planet GenServer reference by his name
  defp via_tuple(name), do: {:via, Registry, {PlanetRegistry, name}}

  @doc """
  Get the resource produced by the planet

  ## Parameter
  - name: `atom` name of the planet

  ## Return
  `atom` resource name
  """
  def get_resource(name) do
    GenServer.call(via_tuple(name), :get_resource)
  end


  @doc """
  Add some robots to the planet

  ## Parameter
  - name: `atom` name of the planet
  - count: `integer` number of robots to add
  """
  def add_robot(name, count) do
    GenServer.call(via_tuple(name), {:add_robot, count})
  end

  @doc """
  Get the number of robot on the planet

  ## Parameter
  - name: `atom` name of the planet

  ## Return
  `integer` number of robots on the planet
  """
  def get_robots(name) do
    IO.puts("Getting robots from #{name}")
    GenServer.call(via_tuple(name), :get_robots)
  end

  @doc """
  Get the cost of a robot on the planet

  ## Parameter
  - name: `atom` name of the planet

  ## Return
  `integer` robot cost
  """
  def get_robot_cost(name) do
    IO.puts("Getting robot cost from #{name}")
    GenServer.call(via_tuple(name), :get_robot_cost)
  end

  @doc """
  Get the production rate of the robots
  working on the planet

  ## Parameter
  - name: `atom` name of the planet

  ## Return
  `integer` production rate
  """
  def get_production_rate(name) do
    GenServer.call(via_tuple(name), :get_production_rate)
  end

  @doc """
  Get the cost to upgrade the planet

  ## Parameter
  - name: `atom` name of the planet

  ## Return
  `integer` upgarde cost
  """
  def get_upgrade_cost(name) do
    GenServer.call(via_tuple(name), :get_upgrade_cost)
  end

  @doc """
  Get if the planet is owned or not

  ## Parameter
  - name: `atom` name of the planet

  ## Return
  `boolean` true if owned, else false
  """
  def get_owned(name) do
    GenServer.call(via_tuple(name), :get_owned)
  end

  @doc """
  Upgrade the planet

  ## Parameter
  - name: `atom` name of the planet
  """
  def upgrade(name) do
    GenServer.cast(via_tuple(name), :upgrade)
  end

  @doc """
  Get the cost of the planet

  ## Parameter
  - name: `atom` name of the planet

  ## Return
  `integer` cost of the planet
  """
  def get_cost(name) do
    GenServer.call(via_tuple(name), :get_cost)
  end

  @doc """
  Get all the information related to the planet

  ## Parameter
  - name: `atom` name of the planet

  ## Return
  `%{}` with the following keys:
  - robot_count
  - cost
  - production_rate
  - robot_price
  - upgrade_cost
  - owned
  - resource
  - level
  """
  def get_all_data(name) do
    GenServer.call(via_tuple(name), :get_all_data)
  end

  @doc """
  Buy the planet

  ## Parameter
  - name: `atom` name of the planet
  """
  def buy_planet(name) do
    GenServer.cast(via_tuple(name), :buy_planet)
  end

  ### GenServer callbacks ###

  @impl true
  def handle_call(:get_resource, _from, state) do
    {:reply, state.resource, state}
  end

  @impl true
  def handle_call(:get_robots, _from, state) do
    # Get the actual robot count from the DynamicSupervisor
    actual_robot_count = get_actual_robot_count(state.name)
    {:reply, actual_robot_count, state}
  end

  @impl true
  def handle_call(:get_robot_cost, _from, state) do
    {:reply, state.robot_price, state}
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
        # If there was enough money to buy
        {:ok, _} ->
          new_state = %{state | owned: true}
          {:noreply, new_state}

        # If not enough money
        {:error, _} ->
          IO.puts("Not enough money to buy planet #{state.name}")
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_call({:add_robot, count}, _from, state) do
    total_cost = count * state[:robot_price]

    # Check if enough money
    case Resource.remove(:dG, total_cost) do
      {:ok, _} ->
        # Add robot to the supervisor
        RobotDynSupervisor.add_worker(
          state[:name],
          count,
          state[:resource],
          state[:robot_maintenance]
        )

        # Update the local state
        new_state = %{state | robot_count: state.robot_count + count}
        new_state = %{new_state | production_rate: calculate_production_rate(new_state)}

        planet_name = to_string(state[:name]) |> String.upcase()
        success_message = "Successfully deployed #{count} robot unit#{if count > 1, do: "s", else: ""} to #{planet_name} for #{total_cost} $dG"

        {:reply, {:ok, success_message}, new_state}

      # If not enough money
      {:error, _} ->
        planet_name = to_string(state[:name]) |> String.upcase()
        error_message = "Insufficient funds to deploy robots to #{planet_name} (#{total_cost} $dG required)"
        {:reply, {:error, error_message}, state}
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

    # Get the actual robot count from the DynamicSupervisor
    actual_robot_count = get_actual_robot_count(state[:name])

    # Update state if robot count is out of sync
    updated_state =
      if actual_robot_count != state.robot_count do
        new_state = %{state | robot_count: actual_robot_count}
        new_state = %{new_state | production_rate: calculate_production_rate(new_state)}
        new_state
      else
        state
      end

    data = %{
      robot_count: actual_robot_count,
      cost: updated_state.cost,
      production_rate: updated_state.production_rate,
      robot_price: updated_state[:robot_price],
      upgrade_cost: upgrade_cost,
      owned: updated_state.owned,
      resource: updated_state.resource,
      level: updated_state.level
    }

    {:reply, data, updated_state}
  end

  # Get the actual number of robot processes from the DynamicSupervisor
  defp get_actual_robot_count(planet_name) do
    try do
      DynamicSupervisor.which_children(planet_name)
      |> length()
    rescue
      _ -> 0
    end
  end
end
