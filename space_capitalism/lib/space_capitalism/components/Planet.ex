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
  def start_link({name, resource}) do
    IO.puts("Planet #{name}")
    {:ok, pid} = RobotDynSupervisor.start_link(name)
    GenServer.start_link(__MODULE__, %{resource: resource, robots: pid, name: name}, name: {:via, Registry, {PlanetRegistry, name}})
  end


  @impl true
  def init(state) do
    IO.puts("Planet process started: #{state[:name]}")
    {:ok, state}
  end

  defp via_tuple(name), do: {:via, Registry, {PlanetRegistry, name}}

  # Obtenir l'état du Planet
  def get_resource(name) do
    IO.puts("Getting resource #{name}")
    GenServer.call(via_tuple(name), :get_resource)
  end

  # Ajoute count Robot à la Planet
  def add_robot(name, count) do
    IO.puts("Adding robots to #{name}")
    GenServer.cast(via_tuple(name), {:add_robot, count})
  end

  @impl true
  def handle_call(:get_resource, _from, state) do
    IO.puts("Handling resource!")
    {:reply, state.resource, state}
  end

  @impl true
  def handle_cast({:add_robot, count}, state) do
    IO.puts("Handling add robot !")
    RobotDynSupervisor.add_worker(state[:name], count, state[:resource])
    {:noreply, state}
  end

end
