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

  # Enlève au plus amount, sinon set le nombre à 0
  def safe_remove(name, amount) do
    Agent.update(name, fn count ->
      if count < amount do
        0
      else
        count - amount
      end
    end)
  end

  # Modifie la resource de {percentage} %
  def modify(name, percentage) do
    Agent.update(name, fn count ->
      count + round(count * percentage)
    end)
  end

  # Set the resource to a specific value
  def set(name, amount) do
    Agent.update(name, fn _count -> amount end)
  end
end
