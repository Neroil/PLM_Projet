defmodule PlanetSupervisor do
  use Supervisor

  @moduledoc """
  Supervisor to handle the planet GenServer
  """

  @doc """
  Start the PlanetSupervisor
  """
  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children =
      [
        # PlanetRegistry
        %{start: {PlanetRegistry, :start_link, []}, id: PlanetRegistry}
      ] ++
        # All the planets
        Enum.map(get_planets(), fn {name, cost, resource_type, base_cost, base_production,
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

  @doc """
  Get a list of all the planet available in the game and theirs inital values

  ## Return
  A list of tuple like `{name, cost, resource, rbPrice, rbMaintenance, owned}`
  - name: `atom` name of the planet
  - cost: `integer` cost of the planet
  - resource: `atom` name of the resource
  - rbPrice: `integer` Price of a robot on the planet
  - rbMaintenance: `integer` Cost of maintenance of a robot
  - owned: `boolean` true if the planet is owned by the player, otherwise false
  """
  def get_planets() do
    [
      {:mars, 0, :iron, 100, 100, true},
      {:proxima, 5_000, :gold, 500, 120, false},
      {:barnard, 15_000, :iron, 1_000, 150, false},
      {:struve, 25_000, :uranium, 5_000, 180, false},
      {:gui_ed, 100_000, :gold, 20_000, 200, false},
      {:toi, 400_000, :plutonium, 50_000, 250, false},
      {:trivia, 750_000, :uranium, 100_000, 300, false},
      {:ze_bi, 1_200_000, :plutonium, 150_000, 350, false},
      {:yver_dion, 3_000_000, :hasheidium, 300_000, 400, false},
      {:ches_om, 10_000_000, :hasheidium, 500_000, 500, false}
    ]
  end

  @doc """
  Like `get_planets()` but return only the planets where `owned` is true
  """
  def get_all_owned_planets() do
    Enum.filter(get_planets(), fn {name, _cost, _resource_type, _base_cost, _base_production,
                                  _is_owned} ->
      Planet.get_owned(name)
    end)
  end

  @doc """
  Get the list of the planet with theirs actual data

  ## Return
  A map with as key the planet's name as `atom` and value another map with keys:
  - id
  - cost
  - name
  - resource_type
  - robots
  - production_rate
  - robot_cost
  - upgrade_cost
  - owned
  """
  def get_all_planets() do
    Enum.map(get_planets(), fn {name, cost, resource_type, _base_cost, _base_production, _is_owned} ->
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

  @doc """
  Buy a planet that then belongs to the

  ## Parameter
  - planet_strin: `string` planet's name
  """
  def buy_planet(planet_string) do
    # Convert planet_id into atom
    planet_id = get_atom(planet_string)

    # Check if planet exists
    case Enum.find(get_planets(), fn {name, _, _, _, _, _} -> name == planet_id end) do
      nil ->
        {:error, "Planet #{planet_id} does not exist"}

      {_name, cost, _resource, _rb_price, _rb_maintenance, is_owned} ->
        if is_owned do
          {:error, "Planet #{planet_id} is already owned"}
        else
          # Try buying
          case Resource.remove(:dG, cost) do
            {:ok, _} ->
              Planet.buy_planet(planet_id)
              {:ok, "Planet #{planet_id} purchased successfully"}

            {:error, _}  ->
              {:error, "Not enough money to buy planet #{planet_id}"}
          end
        end
    end
  end
  # Helper function to get a planet by its name
  # Converts string to existing atom if input is binary, otherwise returns as-is
  defp get_atom(string) do
    # Convert planet_id into atom
    if is_binary(string), do: String.to_existing_atom(string), else: string
  end

end
