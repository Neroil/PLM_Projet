defmodule ResourceSupervisor do
  use Supervisor

  def start_link(_) do
    IO.puts("ResourceSupervisor")
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def getResources() do
    [:iron, :gold, :uranium, :plutonium, :hasheidium, :dG, :crypto1, :crypto2, :crypto3, :robot, :robot_maintenance_cost]
  end

  def setInitialResources(res) do
    # Set intial resources for the game
    case res do
      :iron -> 5
      :dG -> 100
      :crypto1 -> 10
      _ -> 0
    end
  end

  def addWorker(nbOfWorker, maintenance_cost) do
    Resource.add(:robot, nbOfWorker)
    Resource.add(:robot_maintenance_cost, maintenance_cost * nbOfWorker)
  end

  def remove_worker(count) do
    Resource.safe_remove(:robot, count)
  end

  def applyMaintenanceCost() do
    # Apply the maintenance cost of the robots
    maintenance_cost = Resource.get(:robot_maintenance_cost)
    dG = Resource.get(:dG)

    Resource.set(:dG, dG - maintenance_cost)
  end

  def getAllResources() do
    #Enum.map
    Enum.map(getResources(), fn res ->
      {res, Resource.get(res)}
    end
    )
    |> Enum.into(%{})
  end

  @impl true
  def init(_) do
    children = Enum.map(getResources(), fn res ->
      %{start: {Resource, :start_link, [setInitialResources(res), res]}, id: res}
    end)
    Supervisor.init(children, strategy: :one_for_one)
  end
end
