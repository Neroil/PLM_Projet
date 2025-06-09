defmodule ResourceSupervisor do
  use Supervisor

  @moduledoc """
  This supervisor handle all the Agents for the resources
  """

  @doc """
  Start the ResourceSupervisor
  """
  def start_link(_) do
    IO.puts("ResourceSupervisor")
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = Enum.map(get_resources(), fn res ->
      %{start: {Resource, :start_link, [set_initial_resources(res), res]}, id: res}
    end)
    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Get a list of `atom` with all the available resources
  """
  def get_resources() do
    [:iron, :gold, :uranium, :plutonium, :hasheidium, :dG, :crypto1, :crypto2, :crypto3, :robot, :robot_maintenance_cost]
  end

  @doc """
  Add some workers (robots)

  ## Parameter
  - nb_worker: `integer` number of robot to add
  - maintenance_cost: `integer` cost of maintenance of 1 robot
  """
  def add_worker(nb_worker, maintenance_cost) do
    Resource.add(:robot, nb_worker)
    Resource.add(:robot_maintenance_cost, maintenance_cost * nb_worker)
  end

  @doc """
  Remove some workers (robots)

  ## Parameter
  - nb_worker: `integer` number of robot to remove
  """
  def remove_worker(count) do
    Resource.safe_remove(:robot, count)
  end

  @doc """
  Get a list of tuple containing the resource name `atom` and its value `integer`
  """
  def get_all_resources() do
    #Enum.map
    Enum.map(get_resources(), fn res ->
      {res, Resource.get(res)}
    end
    )
    |> Enum.into(%{})
  end
  # Set initial resources for the game
  # Defines starting amounts for each resource type
  defp set_initial_resources(res) do
    case res do
      :iron -> 5
      :dG -> 100
      :crypto1 -> 10
      _ -> 0
    end
  end
end
