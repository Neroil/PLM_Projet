defmodule SpaceCapitalism.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SpaceCapitalismWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:space_capitalism, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SpaceCapitalism.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: SpaceCapitalism.Finch},

      # Start to serve requests, typically the last entry
      SpaceCapitalismWeb.Endpoint,

      # Main Supervisor of the game
      GameSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SpaceCapitalism.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SpaceCapitalismWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
