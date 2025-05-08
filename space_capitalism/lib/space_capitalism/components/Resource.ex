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
    Agent.update(name, fn count -> max(count - amount, 0) end)
  end
end
