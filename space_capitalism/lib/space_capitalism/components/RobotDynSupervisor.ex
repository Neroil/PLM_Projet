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
  def add_worker(planet, count) do
    IO.puts("add_worker #{planet}")
    resource = Planet.get_resource(planet)

    for _ <- 1..count do
      DynamicSupervisor.start_child(planet, {Robot, [:start_link, {1000, resource}]})

    end
  end

end
