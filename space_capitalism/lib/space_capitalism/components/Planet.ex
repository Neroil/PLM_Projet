defmodule Planet do
  use GenServer

  # Démarrer un Planet avec un nom et une ressource initiale
  def start_link({name, resource}) do
    IO.puts("Planet #{name}")
    {:ok, pid} = RobotDynSupervisor.start_link(name)
    GenServer.start_link(__MODULE__, %{resource: resource, robots: pid, name: name})
  end


  @impl true
  def init(state) do
    {:ok, state}
  end

  # Obtenir l'état du Planet
  def get_resource(name) do
    GenServer.call(name, :get_resource)
  end

  # Ajoute count Robot à la Planet
  def add_robot(name, count) do
    IO.puts("Adding robots to #{name}")
    GenServer.cast(name, {:add_robot, count})
  end

  @impl true
  def handle_call(:get_resource, _from, state) do
    {:reply, state.resource, state}
  end

  @impl true
  def handle_cast({:add_robot, count}, state) do
    IO.puts("Handling add robot !")
    RobotDynSupervisor.add_worker(state[:name], count)
    {:no_reply, state}
  end

end
