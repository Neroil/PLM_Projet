defmodule ResourceSupervisor do
  use DynamicSupervisor

  def start_link(planet) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: planet)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # Ajouter un worker dynamiquement
  def add_worker(planet, count) do
    resource = Planet.get_resource(planet)
    
    for _ <- 1..count do
      DynamicSupervisor.start_child(planet, {Robot, {1000, resource}})
    end
  end

end
