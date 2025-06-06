defmodule StockMarket do
  use GenServer

  import ResourceSupervisor
  import Resource

  def start_link(_) do
    prices = %{
      iron: %{price: 10, trend: 0},
      gold: %{price: 200, trend: 0},
      uranium: %{price: 500, trend: 0},
      plutonium: %{price: 2000, trend: 0},
      hasheidium: %{price: 5000, trend: 0},
      crypto1: %{price: 10, trend: 0},
      crypto2: %{price: 100, trend: 0},
      crypto3: %{price: 1000, trend: 0}
    }

    GenServer.start_link(__MODULE__, prices, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Process.send_after(self(), :randomizePrices, 2000)
    {:ok, state}
  end

  def get_prices() do
    GenServer.call(__MODULE__, :get_prices)
  end

  def sell(resource, quantity) do
    GenServer.call(__MODULE__, {:sell, resource, quantity})
  end

  def buy(resource, quantity) do
    GenServer.call(__MODULE__, {:buy, resource, quantity})
  end

  def update(resource, difference) do
    GenServer.cast(__MODULE__, {:update, resource, difference})
  end

  @impl true
  def handle_call(:get_prices, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:update, resource, difference}, state) do
    trend = if difference > 0, do: 1, else: -1

    new_state =
      Map.put(state, resource, %{price: state[resource][:price] + difference, trend: trend})

    {:noreply, new_state}
  end

  @impl true
  def handle_call({:sell, resource, quantity}, _from, state) do
    case Resource.remove(resource, quantity) do
      {:ok, _} ->
        Resource.add(:dG, quantity * state[resource][:price])

        {:reply,
         {:ok,
          "Successfully sold #{quantity} #{resource} for #{quantity * state[resource][:price]} $dG"},
         state}

      {:error, _} ->
        {:reply, {:error, "Insufficient #{resource} to sell (#{quantity} requested)"}, state}
    end
  end

  @impl true
  def handle_call({:buy, resource, quantity}, _from, state) do
    total_cost = quantity * state[resource][:price]

    case Resource.remove(:dG, total_cost) do
      {:ok, _} ->
        Resource.add(resource, quantity)

        {:reply, {:ok, "Successfully bought #{quantity} #{resource} for #{total_cost} $dG"},
         state}

      {:error, _} ->
        {:reply, {:error, "Insufficient funds (#{total_cost} $dG required)"}, state}
    end
  end

  defp generateNewPrice(actualPrice) do
    newVal = Enum.random(0..200) - 100

    if actualPrice + newVal > 0 do
      newVal
    else
      actualPrice - 1
    end
  end

  defp generateRandomTime() do
    Enum.random(10..45) * 1000
  end

  @impl true
  def handle_info(:randomizePrices, state) do
    for res <- Map.keys(state), do: update(res, generateNewPrice(state[res][:price]))

    # Continue la boucle
    Process.send_after(self(), :randomizePrices, generateRandomTime())
    {:noreply, state}
  end
end
