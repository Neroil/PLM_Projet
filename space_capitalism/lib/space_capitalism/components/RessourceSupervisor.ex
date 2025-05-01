defmodule ResourceSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      {Resource, [500, name: :iron]},
      {Resource, [0, name: :gold]},
      {Resource, [0, name: :uranium]},
      {Resource, [0, name: :plutonium]},
      {Resource, [0, name: :hasheidium]},
      {Resource, [10000, name: :dG]},
      {Resource, [1000, name: :crypto1]},
      {Resource, [0, name: :crypto2]},
      {Resource, [0, name: :crypto3]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
