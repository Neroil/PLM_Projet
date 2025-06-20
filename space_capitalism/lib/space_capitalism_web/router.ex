defmodule SpaceCapitalismWeb.Router do
  use SpaceCapitalismWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SpaceCapitalismWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug Plug.Static,
    at: "/",
    from: :space_capitalism,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SpaceCapitalismWeb do
    pipe_through :browser

    get "/", PageController, :home
  end


  scope "/", SpaceCapitalismWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/game", GameLive
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:space_capitalism, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SpaceCapitalismWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
