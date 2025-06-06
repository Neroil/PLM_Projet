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

  def upgrade_production_amount(resource, multiplier) do
    # Upgrade the production amount of the robots
    # This is a placeholder for actual implementation
    IO.puts("Upgrading production amount of #{resource} by #{multiplier}x")

    # Get all the planets with the provided resource
    planets_with_resource =
      Registry.select(PlanetRegistry, [{{:_, :"$1", :"$2"}, [], [:"$1"]}])
      |> Enum.filter(fn planet_name ->
        case Registry.lookup(PlanetRegistry, planet_name) do
          [{pid, _}] ->
            case GenServer.call(pid, :get_resource) do
              ^resource -> true
              _ -> false
            end

          [] ->
            false
        end
      end)

    Enum.each(planets_with_resource, fn planet_name ->
      IO.puts("Upgrading robots on planet #{planet_name} for resource #{resource}")
      # Here you would typically send a message to the robots to upgrade their production amount
      children =
        DynamicSupervisor.which_children(planet_name)
        |> Enum.map(fn {_, pid, _, _} -> pid end)

      Enum.each(children, fn pid ->
        GenServer.cast(pid, {:upgrade_efficiency, multiplier})
      end)
    end)
  end

  # Ajouter un worker dynamiquement
  def add_worker(planet, count, resource, maintenance_cost) do
    for x <- 1..count do
      IO.puts("add_worker #{planet} #{x}")

      DynamicSupervisor.start_child(planet, {Robot, {1000, resource}})
    end

    ResourceSupervisor.addWorker(count, maintenance_cost)
  end

  def remove_worker(planet, count) do
    children =
      DynamicSupervisor.which_children(planet)
      |> Enum.take(count)

    for {_, pid, _, _} <- children do
      DynamicSupervisor.terminate_child(planet, pid)
    end

    ResourceSupervisor.remove_worker(count)
  end
end
