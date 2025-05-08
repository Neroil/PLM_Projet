defmodule Robot do
  use GenServer

  # Démarre le GenServer
  def start_link({time, resource}) do
    GenServer.start_link(__MODULE__, %{time: time, resource: resource})
  end

  # Callback pour initialiser l'état
  @impl true
  def init(state) do
    # # Démarre la boucle
    IO.puts("Bip boop, I am a robot !!")
    Process.send_after(self(), :work, state[:time])
    {:ok, state}
  end

  # Gère les messages : ici l'action et la récursion
  @impl true
  def handle_info(:work, state) do
    Resource.add(state[:resource], 1)
    :timer.sleep(state[:time]) # Temps d'attente entre actions

    # Continue la boucle
    Process.send_after(self(), :work, 0)
    {:noreply, state}
  end
end
