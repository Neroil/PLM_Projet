defmodule Resource do
  use Agent


  # Démarrer un Agent avec un état initial et un nom unique
  def start_link(initial_count, name) do
    IO.puts("Ressource")
    Agent.start_link(fn -> initial_count end, name: name)
  end

  # Obtenir le nombre actuel de ressources
  def get(name) do
    Agent.get(name, fn count -> count end)
  end

  # Ajouter des ressources
  def add(name, amount) do
    Agent.update(name, fn count -> count + amount end)
  end

  # Enlever des ressources
  def remove(name, amount) do
    Agent.get_and_update(name, fn count ->
      if count >= amount do
        # Successful removal
        {{:ok, count - amount}, count - amount}
      else
        # Cannot remove more than available
        {{:error, :insufficient_resources}, count}
      end
    end)
  end
end
