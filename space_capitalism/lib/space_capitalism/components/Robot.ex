defmodule Robot do
  use GenServer

  # Démarre le GenServer
  def start_link({time, ressource}) do
    GenServer.start_link(__MODULE__, {time, ressource}, name: __MODULE__)
  end

  # Callback pour initialiser l'état
  @impl true
  def init(state) do
    # Démarre la boucle
    Process.send_after(self(), :work, 0)
    {:ok, state}
  end

  # Gère les messages : ici l'action et la récursion
  @impl true
  def handle_info(:work, {time, ressource}) do
    Resource.add(ressource, 1)
    IO.puts("Add 1 to #{ressource}")
    :timer.sleep(time) # Temps d'attente entre actions

    # Continue la boucle
    Process.send_after(self(), :work, 0)
    {:noreply, {time, ressource}}
  end
end
