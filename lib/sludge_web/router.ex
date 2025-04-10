defmodule SludgeWeb.Router do
  import Phoenix.LiveDashboard.Router
  use SludgeWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SludgeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug :admin_auth
  end

  scope "/", SludgeWeb do
    pipe_through :browser

    live "/", StreamViewerLive, :show

    live "/recordings", RecordingLive.Index, :index
    live "/recordings/:id", RecordingLive.Show, :show
  end

  scope "/streamer", SludgeWeb do
    pipe_through :auth
    pipe_through :browser

    live "/", StreamerLive, :show

    live_dashboard "/dashboard",
      metrics: SludgeWeb.Telemetry,
      additional_pages: [exwebrtc: ExWebRTCDashboard]
  end

  defp admin_auth(conn, _opts) do
    username = Application.fetch_env!(:sludge, :admin_username)
    password = Application.fetch_env!(:sludge, :admin_password)
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end
