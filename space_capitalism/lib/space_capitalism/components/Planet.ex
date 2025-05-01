defmodule Planet do
  use GenServer

  # Démarrer un Planet avec un nom et une ressource initiale
  def start_link({name, resource}) do
    GenServer.start_link(__MODULE__, resource, name: name)
  end


  @impl true
  def init(resource) do
    {:ok, %{resource: resource}}
  end

  # Obtenir l'état du Planet
  def get_resource(name) do
    GenServer.call(via_tuple(name), :get_resource)
  end

  @impl true
  def handle_call(:get_resource, _from, state) do
    {:reply, state.resource, state}
  end
end
