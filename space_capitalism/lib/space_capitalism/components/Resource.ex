defmodule Resource do
  use Agent

  @moduledoc """
  This module define the agent to handle a the resources
  """

  @doc """
  Start the agent

  ## Parameter
  - initial_count: `integer` quantity of the resource owned at the initialisation
  - name: `atom` name of the resource
  """
  def start_link(initial_count, name) do
    Agent.start_link(fn -> initial_count end, name: name)
  end

  @doc """
  Get the actual quantity of the resource

  ## Parameter
  - name: `atom` name of the resource
  """
  def get(name) do
    Agent.get(name, fn count -> count end)
  end

  @doc """
  Add a certain amount to the resource

  ## Parameter
  - name: `atom` name of the resource
  - amount: `integer` amount to add
  """
  def add(name, amount) do
    Agent.update(name, fn count -> count + amount end)
  end

  @doc """
  Remove a certain amount to the resource. Fail if not enough of the resource

  ## Parameter
  - name: `atom` name of the resource
  - amount: `integer` amount to remove

  ## Return
  A tuple with either `:ok` and the amount remianing of the resource
  or `:error` and an `atom` with why the remove failed

  `{:ok, 1000}`

  `{:error, :insufficient_resources}`
  """
  def remove(name, amount) do
    Agent.get_and_update(name, fn count ->
      if count >= amount do
        # Successful removal
        {{:ok, count - amount}, count - amount}
      else
        # Cannot remove more than available
        {{:error, :insufficient_resources}, count}
      end
    end)
  end

  @doc """
  Remove a certain amount to the resource.
  If the amount to remove is greater than the possessed one, the quantity is set to 0

  ## Parameter
  - name: `atom` name of the resource
  - amount: `integer` amount to remove
  """
  def safe_remove(name, amount) do
    Agent.update(name, fn count ->
      if count < amount do
        0
      else
        count - amount
      end
    end)
  end

  @doc """
  Modifiy the resource quantity of an amount represented in percentage

  ## Parameter
  - name: `atom` name of the resource
  - percentage: `float` percentage of quantity to remove/add
  """
  def modify(name, percentage) do
    Agent.update(name, fn count ->
      count + round(count * percentage)
    end)
  end

  @doc """
  Set the resource quantity to a specific number

  ## Parameter
  - name: `atom` name of the resource
  - amount: `integer` new value for the resource
  """
  def set(name, amount) do
    Agent.update(name, fn _count -> amount end)
  end
end
