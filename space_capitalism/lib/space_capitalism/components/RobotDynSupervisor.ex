defmodule RobotDynSupervisor do
  use DynamicSupervisor

  @moduledoc """
  This module handle the robot GenServer for one planet
  """

  @doc """
  Start the DynamicSupervisor

  ## Parameter
  - planet: `atom` name of the planet that this instance will supervise
  """
  def start_link(planet) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: planet)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Add some new workers (robots) to a planet

  ## Parameter
  - planet: `atom` name of the planet
  - count: `integer` number of worker to add
  - resource: `atom` name of the resource that the worker will produce
  - maintenance_cost: `integer` cost of maintenance of the robot
  """
  def add_worker(planet, count, resource, maintenance_cost) do
    for x <- 1..count do
      IO.puts("add_worker #{planet} #{x}")
      DynamicSupervisor.start_child(planet, {Robot, {1000, resource}})
    end

    ResourceSupervisor.add_worker(count, maintenance_cost)
  end

  @doc """
  Remove some worker (robot) from a planet

  ## Parameter
  - planet: `atom` name of the planet
  - count: `integer` number of worker to remove
  """
  def remove_worker(planet, count) do
    children =
      DynamicSupervisor.which_children(planet)
      |> Enum.take(count)

    for {_, pid, _, _} <- children do
      DynamicSupervisor.terminate_child(planet, pid)
    end

    ResourceSupervisor.remove_worker(length(children))
  end
end
