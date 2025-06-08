defmodule StockMarket do
  use GenServer

  @moduledoc """
  This module handle the stock market of the game
  """

  @doc """
  Start the StockMarket GenServer with the base prices of the resources
  """
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
    # Start the timer for prices update
    Process.send_after(self(), :randomize_prices, 2000)

    {:ok, state}
  end

  @doc """
  Get the list of prices and the trend of the resources

  ## Return
  A map with as key the resource's name and as value
  another map with `price` and `trend` as keys
  """
  def get_prices() do
    GenServer.call(__MODULE__, :get_prices)
  end

  @doc """
  Sell a resource for the actual price

  ## Parameter
  - resource: `atom` name of the resource
  - quantity: `integer` quantity of resource to sell
  """
  def sell(resource, quantity) do
    GenServer.call(__MODULE__, {:sell, resource, quantity})
  end

  @doc """
  Buy a resource for the actual price

  ## Parameter
  - resource: `atom` name of the resource
  - quantity: `integer` quantity of resource to buy
  """
  def buy(resource, quantity) do
    GenServer.call(__MODULE__, {:buy, resource, quantity})
  end

  @doc """
  Update the price of resource

  ## Parameter
  - resource: `atom` name of the resource
  - difference: `integer` difference of price between the actual value and the new value
  """
  def update(resource, difference) do
    GenServer.cast(__MODULE__, {:update, resource, difference})
  end

  # Handle the prices get
  @impl true
  def handle_call(:get_prices, _from, state) do
    {:reply, state, state}
  end

  # Handle the price update
  @impl true
  def handle_cast({:update, resource, difference}, state) do
    trend = if difference > 0, do: 1, else: -1

    new_state =
      Map.put(state, resource, %{price: state[resource][:price] + difference, trend: trend})

    {:noreply, new_state}
  end

  # Handle a selling transaction
  @impl true
  def handle_call({:sell, resource, quantity}, _from, state) do
    # Remove the quantity of resource and check if the player has enough resource
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

  # Handle a buying transaction
  @impl true
  def handle_call({:buy, resource, quantity}, _from, state) do
    total_cost = quantity * state[resource][:price]

    # Remove the quantity of money if the player is rich enough
    case Resource.remove(:dG, total_cost) do
      {:ok, _} ->
        Resource.add(resource, quantity)

        {:reply, {:ok, "Successfully bought #{quantity} #{resource} for #{total_cost} $dG"},
         state}

      {:error, _} ->
        {:reply, {:error, "Insufficient funds (#{total_cost} $dG required)"}, state}
    end
  end

  # Handle the random variation of prices
  @impl true
  def handle_info(:randomize_prices, state) do
    for res <- Map.keys(state), do: update(res, generate_new_price(state[res][:price]))

    # Continue the loop
    Process.send_after(self(), :randomize_prices, generate_random_time())
    {:noreply, state}
  end

  # Generate a random new price base on the actual price
  defp generate_new_price(actual_price) do
    newVal = Enum.random(0..200) - 100

    if actual_price + newVal > 0 do
      newVal
    else
      actual_price - 1
    end
  end

  # generate a random time for the next prices's variation
  defp generate_random_time() do
    Enum.random(10..45) * 1000
  end
end
