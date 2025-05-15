defmodule SpaceCapitalismWeb.GameComponents do
  use Phoenix.Component
  alias Phoenix.HTML.Form
  # Import raw/1 function
  import Phoenix.HTML, only: [raw: 1]
  # Import all Form functions including hidden_input/3
  import Phoenix.HTML.Form

  # Reusable section header component
  def section_header(assigns) do
    ~H"""
    <h2 class={"section-header #{@color_class} border-#{@color_base} break-words hyphens-auto"}>
      <%= raw(@title) %>
    </h2>
    """
  end

  # Reusable resource display component
  def resource_display(assigns) do
    assigns = assign_new(assigns, :class, fn -> "text-slate-100" end)
    assigns = assign_new(assigns, :unit, fn -> nil end)

    ~H"""
    <div class="flex justify-between">
      <span><%= @label %>:</span>
      <span class={@class}><%= @value %><%= if @unit, do: " #{@unit}" %></span>
    </div>
    """
  end

  # Planet component
  def planet_item(assigns) do
    ~H"""
    <div class={"planet-item #{@bg_class} border border-slate-700 #{@padding} shadow-md hover:#{@hover_class} transition-all duration-150"}>
      <div class="flex justify-between items-start mb-1.5">
      <div class="flex items-center gap-2">

        <h3 class={"text-md font-semibold #{@name_color}"}><%= @planet.name %></h3>
        </div>
        <%= if @show_resource_badge do %>
          <span class={resource_badge_class(@planet.resource_type)}>
            <%= @planet.resource_type %>
          </span>
        <% end %>
      </div>

      <%= if @show_details do %>
        <div class="text-xs space-y-0.5 mb-2 text-slate-400">
          <.resource_display label="ROBOT_UNITS ::" value={@planet.robots} class="text-green-400 font-semibold" />
          <.resource_display label="PROD_OUTPUT ::" value={@planet.production_rate} unit="/cycle" class="text-green-400 font-semibold" />
        </div>
      <% end %>

      <div class="mt-2 flex flex-wrap gap-1.5">
        <%= for button <- @buttons do %>
          <button phx-click={button.action} phx-value-planet={@planet.id} class={button.class}>
            <%= button.text %>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  # Market item component
  def market_item(assigns) do
    ~H"""
    <div class="market-item bg-slate-900/70 border border-slate-700 p-1.5 hover:border-yellow-500/70">
      <div class="flex justify-between items-center mb-1">
        <span class="text-slate-200 uppercase font-semibold"><%= @resource %></span>
        <span class={"font-bold " <> if(@data.trend > 0, do: "text-green-400", else: "text-red-400")}>
          <%= @data.price %> $dG
          <%= if @data.trend > 0 do %>▲<% else %>▼<% end %>
        </span>
      </div>
      <div class="mt-1 flex flex-wrap gap-1.5 justify-between">
        <.market_action
          action="sell_resource"
          resource={@resource}
          button_text="SELL"
          button_class="pixel-button pixel-button-yellow text-[0.6rem] px-1.5 py-1"
          max_value={Map.get(@resources, String.to_atom(String.downcase(@resource)))}
        />
        <.market_action
          action="buy_resource"
          resource={@resource}
          button_text="BUY"
          button_class="pixel-button pixel-button-blue text-[0.6rem] px-1.5 py-1"
        />
      </div>
    </div>
    """
  end

  # Market action component (buy/sell)
  def market_action(assigns) do
    assigns = assign_new(assigns, :max_value, fn -> nil end)
    # Properly assign variables to assigns
    assigns =
      assign(
        assigns,
        :input_name,
        "#{String.downcase(assigns.action)}_amount_#{assigns.resource}"
      )

    assigns =
      assign(
        assigns,
        :input_id,
        "#{String.downcase(String.replace(assigns.action, "_resource", ""))}-#{assigns.resource}"
      )

    ~H"""
    <div class="flex items-center space-x-1">
      <label for={@input_id} class="sr-only"><%= String.capitalize(@action) %> <%= @resource %></label>
      <input
        type="number"
        name={@input_name}
        id={@input_id}
        min="0"
        max={@max_value}
        class="input-pixel w-12"
        placeholder="QTY"
      />
      <button
        phx-click={@action}
        phx-value-resource={@resource}
        phx-target={["##{@input_id}"]}
        class={@button_class}
      >
        <%= @button_text %>
      </button>
    </div>
    """
  end

  # Upgrade item component
  def upgrade_item(assigns) do
    ~H"""
    <div class="upgrade-item bg-slate-900/70 border border-slate-700 p-1.5 flex justify-between items-center hover:border-sky-500/70">
      <div class="text-xs">
        <span class="font-semibold text-slate-100 text-sm"><%= @upgrade.name %></span>
        <p class="text-slate-400 text-[0.65rem] leading-tight"><%= @upgrade.description %></p>
      </div>
      <button phx-click="buy_upgrade" phx-value-upgrade={@upgrade.id} class="pixel-button pixel-button-purple text-[0.6rem] px-1.5 py-1 whitespace-nowrap">
        RESEARCH (<%= @upgrade.cost %> $dG)
      </button>
    </div>
    """
  end

  # Utility function for resource badge classes
  defp resource_badge_class(resource_type) do
    suffix =
      case resource_type do
        "Iron" -> "-Fe"
        "Gold" -> "-Or"
        "Uranium" -> "-Ur"
        "Plutonium" -> "-Pu"
        "Hasheidium" -> "-Hu"
        _ -> "-Default"
      end

    "resource-badge resource-badge#{suffix}"
  end
end
