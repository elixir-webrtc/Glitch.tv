defmodule GlitchWeb.RecordingLive.Show do
  use GlitchWeb, :live_view

  alias Glitch.Recordings

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:recordings, Recordings.list_five_recordings())
      |> assign(:enable_recordings, Glitch.FeatureFlags.recordings_enabled())

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    recording =
      if connected?(socket) do
        Recordings.get_and_increment_views!(id)
      else
        Recordings.get_recording!(id)
      end

    socket =
      socket
      |> assign(:page_title, recording.title)
      |> assign(:recording, recording)

    {:noreply, socket}
  end
end
