defmodule UpgradeManager do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_upgrades() do
    %{
      "iron_boost" => %{cost: 2500, resource: :iron, multiplier: 1.25, name: "Iron Harvesting Boost", description: "Increase iron production by 25%"},
      "gold_boost" => %{cost: 5000, resource: :gold, multiplier: 1.25, name: "Gold Mining Boost", description: "Increase gold production by 25%"},
      "uranium_boost" => %{cost: 7500, resource: :uranium, multiplier: 1.25, name: "Uranium Extraction Boost", description: "Increase uranium production by 25%"}
    }
  end

  def get_upgrade(upgrade_id) do
    upgrades = get_upgrades()
    Map.get(upgrades, upgrade_id)
  end

  def buy_upgrade(upgrade_id) do
    IO.puts("Buying upgrade: #{upgrade_id}")

    # Get upgrade from central definition
    case get_upgrade(upgrade_id) do
      nil ->
        {:error, "Unknown upgrade: #{upgrade_id}"}

      upgrade ->
        case Resource.get(:dG) do
          money when money >= upgrade.cost ->
            # Deduct the cost
            case Resource.remove(:dG, upgrade.cost) do
              {:ok, _} ->
                # Apply the upgrade using your function
                upgrade_production_amount(upgrade.resource, upgrade.multiplier)

                {:ok,
                 "#{upgrade_id} upgrade applied! #{upgrade.resource} production increased by #{round((upgrade.multiplier - 1) * 100)}%"}

              {:error, reason} ->
                {:error, "Payment failed: #{reason}"}
            end

          _ ->
            {:error,
             "Insufficient funds for upgrade #{upgrade_id} (#{upgrade.cost} $dG required)"}
        end
    end
  end

  def upgrade_production_amount(resource, multiplier) do
    IO.puts("Upgrading production amount of #{resource} by #{multiplier}x")

    # Get all the planets with the provided resource
    planets_with_resource =
      Registry.select(PlanetRegistry, [{{:_, :"$1", :"$2"}, [], [:"$1"]}])
      |> Enum.filter(fn planet_name ->
        case Registry.lookup(PlanetRegistry, planet_name) do
          [{pid, _}] ->
            case GenServer.call(pid, :get_resource) do
              ^resource -> true
              _ -> false
            end

          [] ->
            false
        end
      end)

    Enum.each(planets_with_resource, fn planet_name ->
      IO.puts("Upgrading robots on planet #{planet_name} for resource #{resource}")
      # Here you would typically send a message to the robots to upgrade their production amount
      children =
        DynamicSupervisor.which_children(planet_name)
        |> Enum.map(fn {_, pid, _, _} -> pid end)

      Enum.each(children, fn pid ->
        GenServer.cast(pid, {:upgrade_efficiency, multiplier})
      end)
    end)
  end
end
