defmodule PlanetSupervisor do
  alias ElixirSense.Log
  use Supervisor

  def start_link(_) do
    IO.puts("PlanetSupervisor")
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def getPlanets() do
    [
      {:mars, 0, :iron, 100, 100, true},
      {:proxima, 5000, :gold, 150, 120, false},
      {:barnard, 8000, :iron, 200, 150, false},
      {:struve, 15000, :uranium, 250, 180, false},
      {:gui_ed, 25000, :gold, 300, 200, false},
      {:toi, 40000, :plutonium, 400, 250, false},
      {:trivia, 65000, :uranium, 500, 300, false},
      {:ze_bi, 100_000, :plutonium, 650, 350, false},
      {:yver_dion, 160_000, :hasheidium, 800, 400, false},
      {:ches_om, 250_000, :hasheidium, 1000, 500, false}
    ]
  end

  def getAllOwnedPlanets() do
    Enum.filter(getPlanets(), fn {_name, _resource_type, _base_cost, _base_production, is_owned} ->
      is_owned
    end)
  end

  def getAllPlanets() do
    Enum.map(getPlanets(), fn {name, cost, resource_type, _base_cost, _base_production, _is_owned} ->
      planet_data = Planet.get_all_data(name)

      {
        name,
        %{
          id: name,
          cost: cost,
          name: to_string(name) |> String.capitalize(),
          resource_type: to_string(resource_type) |> String.capitalize(),
          robots: planet_data.robot_count,
          production_rate: planet_data.production_rate,
          robot_cost: planet_data.robot_price,
          upgrade_cost: planet_data.upgrade_cost,
          owned: planet_data.owned
        }
      }
    end)
    |> Enum.into(%{})
  end

  #Helper function to get a planet by its name
  def getAtom(string) do
    # Convert planet_id into atom
    id =
      if is_binary(string), do: String.to_existing_atom(string), else: string
  end

  def addRobot(planet_id, count \\ 1) do
    # Cast to atom if string
    Planet.add_robot(getAtom(planet_id), count)
    IO.puts("Added #{count} robots to planet #{getAtom(planet_id)}")
  end

  def upgradePlanet(planet_id) do
    Planet.upgrade(getAtom(planet_id))
  end

  def buyPlanet(planet_string) do
    # Convert planet_id into atom
    planet_id = getAtom(planet_string)

    # Check if planet exists
    case Enum.find(getPlanets(), fn {name, _, _, _, _, _} -> name == planet_id end) do
      nil ->
        {:error, "Planet #{planet_id} does not exist"}

      {_name, cost, _resource, _rb_price, _rb_maintenance, is_owned} ->
        if is_owned do
          {:error, "Planet #{planet_id} is already owned"}
        else
          # Get current money
          case Resource.get(:dG) do
            money when money >= cost ->
              # Call the Planet module to handle the purchase
              Planet.buy_planet(planet_id)
              {:ok, "Planet #{planet_id} purchased successfully"}

            _ ->
              {:error, "Not enough money to buy planet #{planet_id}"}
          end
        end
    end
  end

  @impl true
  def init(_) do
    children =
      [
        %{start: {PlanetRegistry, :start_link, []}, id: PlanetRegistry}
      ] ++
        Enum.map(getPlanets(), fn {name, cost, resource_type, base_cost, base_production,
                                   is_owned} ->
          %{
            start:
              {Planet, :start_link,
               [{name, cost, resource_type, base_cost, base_production, is_owned}]},
            id: name
          }
        end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
