defmodule GlitchWeb.RecordingLive.Index do
  use GlitchWeb, :live_view

  alias Glitch.Recordings

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Recordings")
      |> assign(:recording, nil)
      |> stream(:recordings, Recordings.list_recordings())
      |> assign(:enable_recordings, Glitch.FeatureFlags.recordings_enabled())

    {:ok, socket}
  end

  @impl true
  def handle_info({GlitchWeb.RecordingLive.FormComponent, {:saved, recording}}, socket) do
    {:noreply, stream_insert(socket, :recordings, recording)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    recording = Recordings.get_recording!(id)
    {:ok, _} = Recordings.delete_recording(recording)

    {:noreply, stream_delete(socket, :recordings, recording)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp seconds_to_duration_string(seconds) do
    hours = div(seconds, 3600)
    minutes = div(seconds - hours * 3600, 60)
    seconds = rem(seconds, 60)

    "#{pad_number(hours)}:#{pad_number(minutes)}:#{pad_number(seconds)}"
  end

  defp pad_number(number) when number < 10 do
    "0#{number}"
  end

  defp pad_number(number) do
    "#{number}"
  end
end
