defmodule Robot do
  use GenServer

  @moduledoc """
  This module handle the robot to mine resource on a planet
  """

  @doc """
  Start the Robot GenServer
  """
  def start_link({time, resource}) do
    GenServer.start_link(__MODULE__, %{time: time, resource: resource})
  end

  @impl true
  def init(state) do
    # Initialize with upgrade multipliers
    enhanced_state = Map.merge(state, %{
      efficiency_multiplier: 1.0,    # Affects resource yield
      speed_multiplier: 1.0,         # Affects mining speed
      base_yield: 1,                 # Base amount per work cycle
      upgrade_level: 1               # Robot upgrade level
    })

    # Start the recursive loop that make the robot collect resource
    Process.send_after(self(), :work, enhanced_state[:time])

    {:ok, enhanced_state}
  end

  @doc """
  Upgarde the efficiency of the robot

  ## Parameter
  - robot_pid: Process Id of the robot
  - multiplier: `float` the efficiency will be multiplied by this value
  """
  def upgrade_efficiency(robot_pid, multiplier) do
    GenServer.cast(robot_pid, {:upgrade_efficiency, multiplier})
  end

  @doc """
  Upgarde the speed of the robot

  ## Parameter
  - robot_pid: Process Id of the robot
  - multiplier: `float` the speed will be multiplied by this value
  """
  def upgrade_speed(robot_pid, multiplier) do
    GenServer.cast(robot_pid, {:upgrade_speed, multiplier})
  end

  @doc """
  Get the statics of the robot

  ## Parameter
  - robot_pid: Process Id of the robot

  ## Return
  A map with the following keys:
  - efficiency_multiplier
  - speed_multiplier
  - upgrade_level
  - actual_yield
  - work_interval
  """
  def get_stats(robot_pid) do
    GenServer.call(robot_pid, :get_stats)
  end

  # Handle the work loop
  @impl true
  def handle_info(:work, state) do
    # Calculate actual yield based on base yield and efficiency multiplier
    actual_yield = round(state[:base_yield] * state[:efficiency_multiplier])

    # Add resources to the planet
    Resource.add(state[:resource], actual_yield)

    # Calculate next work interval based on speed multiplier
    next_work_time = round(state[:time] / state[:speed_multiplier])

    Process.send_after(self(), :work, next_work_time)
    {:noreply, state}
  end

  # Handle efficiency upgrades
  @impl true
  def handle_cast({:upgrade_efficiency, new_multiplier}, state) do
    IO.puts("Robot efficiency upgraded to #{new_multiplier}x")
    updated_state = %{state |
      efficiency_multiplier: new_multiplier,
      upgrade_level: state[:upgrade_level] + 1
    }
    {:noreply, updated_state}
  end

  # Handle speed upgrades
  @impl true
  def handle_cast({:upgrade_speed, new_multiplier}, state) do
    IO.puts("Robot speed upgraded to #{new_multiplier}x")
    updated_state = %{state |
      speed_multiplier: new_multiplier,
      upgrade_level: state[:upgrade_level] + 1
    }
    {:noreply, updated_state}
  end

  # Get robot statistics
  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      efficiency_multiplier: state[:efficiency_multiplier],
      speed_multiplier: state[:speed_multiplier],
      upgrade_level: state[:upgrade_level],
      actual_yield: round(state[:base_yield] * state[:efficiency_multiplier]),
      work_interval: round(state[:time] / state[:speed_multiplier])
    }
    {:reply, stats, state}
  end
end
