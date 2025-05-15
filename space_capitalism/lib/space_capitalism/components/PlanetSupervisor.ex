defmodule PlanetSupervisor do
  use Supervisor

  def start_link(_) do
    IO.puts("PlanetSupervisor")
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      %{start: {PlanetRegistry, :start_link, []}, id: PlanetRegistry},
      %{start: {Planet, :start_link, [{:mars, :iron, 100, 100}]}, id: :mars},
      %{start: {Planet, :start_link, [{:proxima, :gold, 100, 100}]}, id: :proxima},
      %{start: {Planet, :start_link, [{:struve, :uranium, 100, 100}]}, id: :struve},
      %{start: {Planet, :start_link, [{:barnard, :iron, 100, 100}]}, id: :barnard},
      %{start: {Planet, :start_link, [{:toi, :plutonium, 100, 100}]}, id: :toi},
      %{start: {Planet, :start_link, [{:gui_ed, :gold, 100, 100}]}, id: :gui_ed},
      %{start: {Planet, :start_link, [{:yver_dion, :hasheidium, 100, 100}]}, id: :yver_dionP},
      %{start: {Planet, :start_link, [{:trivia, :uranium, 100, 100}]}, id: :trivia},
      %{start: {Planet, :start_link, [{:ze_bi, :plutonium, 100, 100}]}, id: :ze_bi},
      %{start: {Planet, :start_link, [{:ches_om, :hasheidium, 100, 100}]}, id: :ches_om}
    ]


    Supervisor.init(children, strategy: :one_for_one)
  end
end
