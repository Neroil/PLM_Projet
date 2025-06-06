defmodule GameSupervisor do
  use Supervisor

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
  def getUpgrades() do
    %{
      "iron_boost" => %{cost: 2500, resource: :iron, multiplier: 1.25, name: "Iron Harvesting Boost", description: "Increase iron production by 25%"},
      "gold_boost" => %{cost: 5000, resource: :gold, multiplier: 1.25, name: "Gold Mining Boost", description: "Increase gold production by 25%"},
      "uranium_boost" => %{cost: 7500, resource: :uranium, multiplier: 1.25, name: "Uranium Extraction Boost", description: "Increase uranium production by 25%"}
    }
  end

  def getUpgrade(upgrade_id) do
    upgrades = getUpgrades()
    Map.get(upgrades, upgrade_id)
  end

  def buyUpgrade(upgrade_id) do
    IO.puts("Buying upgrade: #{upgrade_id}")

    # Get upgrade from central definition
    case getUpgrade(upgrade_id) do
      nil ->
        {:error, "Unknown upgrade: #{upgrade_id}"}

      upgrade ->
        case Resource.get(:dG) do
          money when money >= upgrade.cost ->
            # Deduct the cost
            case Resource.remove(:dG, upgrade.cost) do
              {:ok, _} ->
                # Apply the upgrade using your function
                RobotDynSupervisor.upgrade_production_amount(upgrade.resource, upgrade.multiplier)

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
end
