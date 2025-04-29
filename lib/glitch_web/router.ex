defmodule GlitchWeb.Router do
  import Phoenix.LiveDashboard.Router
  use GlitchWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GlitchWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug :streamer_auth
  end

  scope "/", GlitchWeb do
    pipe_through :browser

    live "/", StreamViewerLive, :show

    live "/recordings", RecordingLive.Index, :index
    live "/recordings/:id", RecordingLive.Show, :show
  end

  scope "/streamer", GlitchWeb do
    pipe_through :auth
    pipe_through :browser

    live "/", StreamerLive, :show

    live_dashboard "/dashboard",
      metrics: GlitchWeb.Telemetry,
      additional_pages: [exwebrtc: ExWebRTCDashboard]
  end

  defp streamer_auth(conn, _opts) do
    username = Application.fetch_env!(:glitch, :streamer_username)
    password = Application.fetch_env!(:glitch, :streamer_password)
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end
