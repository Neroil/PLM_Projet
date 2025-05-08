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
      %{start: {Planet, :start_link, [{:mars, :iron}]}, id: :mars},
      %{start: {Planet, :start_link, [{:proxima, :gold}]}, id: :proxima},
      %{start: {Planet, :start_link, [{:struve, :uranium}]}, id: :struve},
      %{start: {Planet, :start_link, [{:barnard, :iron}]}, id: :barnard},
      %{start: {Planet, :start_link, [{:toi, :plutonium}]}, id: :toi},
      %{start: {Planet, :start_link, [{:gui_ed, :gold}]}, id: :gui_ed},
      %{start: {Planet, :start_link, [{:yver_dion, :hasheidium}]}, id: :yver_dionP},
      %{start: {Planet, :start_link, [{:trivia, :uranium}]}, id: :trivia},
      %{start: {Planet, :start_link, [{:ze_bi, :plutonium}]}, id: :ze_bi},
      %{start: {Planet, :start_link, [{:ches_om, :hasheidium}]}, id: :ches_om}
    ]


    Supervisor.init(children, strategy: :one_for_one)
  end
end
