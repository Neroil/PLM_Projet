defmodule ResourceSupervisor do
  use Supervisor

  def start_link(_) do
    IO.puts("ResourceSupervisor")
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      %{start: {Resource, :start_link, [500]}, id: :iron},
      %{start: {Resource, :start_link, [0]}, id: :gold},
      %{start: {Resource, :start_link, [0]}, id: :uranium},
      %{start: {Resource, :start_link, [0]}, id: :plutonium},
      %{start: {Resource, :start_link, [0]}, id: :hasheidium},
      %{start: {Resource, :start_link, [10000]}, id: :dG},
      %{start: {Resource, :start_link, [1000]}, id: :crypto1},
      %{start: {Resource, :start_link, [0]}, id: :crypto2},
      %{start: {Resource, :start_link, [0]}, id: :crypto3}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
