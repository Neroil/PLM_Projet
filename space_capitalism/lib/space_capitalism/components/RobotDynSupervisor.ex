defmodule RobotDynSupervisor do
  use DynamicSupervisor

  def start_link(planet) do
    IO.puts("RobotDynSupervisor #{planet}")
    DynamicSupervisor.start_link(__MODULE__, nil, name: planet)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # Ajouter un worker dynamiquement
  def add_worker(planet, count, resource, maintenance_cost) do

    for x <- 1..count do
      IO.puts("add_worker #{planet} #{x}")

      DynamicSupervisor.start_child(planet, {Robot, {1000, resource}})
    end

    ResourceSupervisor.addWorker(count, maintenance_cost)
  end

end
