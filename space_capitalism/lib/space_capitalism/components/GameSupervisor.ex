defmodule GameSupervisor do
  use Supervisor
  @moduledoc """
  Main supervisor of the game. It starts the other supervisor.
  """

  @doc """
  Start the supervisor
  """
  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      ResourceSupervisor,
      PlanetSupervisor,
      StockMarket,
      EventManager
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
