defmodule StockMarket do
  use GenServer

  import ResourceSupervisor
  import Resource

  def start_link(_) do
    prices = %{
      iron: %{price: 10, trend: 0},
      gold: %{price: 10, trend: 1},
      uranium: %{price: 10, trend: -1},
      plutonium: %{price: 10, trend: 0},
      hasheidium: %{price: 10, trend: 0},
      crypto1: %{price: 10, trend: 0},
      crypto2: %{price: 10, trend: 0},
      crypto3: %{price: 10, trend: 0},
    }

    IO.puts(__MODULE__)
    GenServer.start_link(__MODULE__, prices, name: __MODULE__)
  end

  def get_prices() do
    IO.puts("get_prices")
    GenServer.call(__MODULE__, :get_prices)
  end

  def sell(resource, quantity) do
    GenServer.cast(__MODULE__, {:sell, resource, quantity})
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
    new_state = Map.put(state, resource, {state[resource][:price] + difference, trend})
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:sell, resource, quantity}, state) do
    case Resource.remove(resource, quantity) do
      {:ok, _} -> Resource.add(:dG, quantity * state[resource][:price])
      {:error, _} -> IO.puts("Not enough #{resource}")
    end
    {:noreply, state}
  end
end
