defmodule ResourceSupervisor do
  use Supervisor

  def start_link(_) do
    IO.puts("ResourceSupervisor")
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      %{start: {Resource, :start_link, [500, :iron]}, id: :iron},
      %{start: {Resource, :start_link, [0, :gold]}, id: :gold},
      %{start: {Resource, :start_link, [0, :uranium]}, id: :uranium},
      %{start: {Resource, :start_link, [0, :plutonium]}, id: :plutonium},
      %{start: {Resource, :start_link, [0, :hasheidium]}, id: :hasheidium},
      %{start: {Resource, :start_link, [10000, :dG]}, id: :dG},
      %{start: {Resource, :start_link, [1000, :crypto1]}, id: :crypto1},
      %{start: {Resource, :start_link, [0, :crypto2]}, id: :crypto2},
      %{start: {Resource, :start_link, [0, :crypto3]}, id: :crypto3}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
