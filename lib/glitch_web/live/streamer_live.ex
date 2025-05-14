defmodule GlitchWeb.StreamerLive do
  use GlitchWeb, :live_view

  alias LiveExWebRTC.Publisher
  alias Phoenix.Socket.Broadcast
  alias GlitchWeb.ChatLive
  alias GlitchWeb.StreamViewerLive

  # XXX add this as defaults in live_ex_webrtc, so that recordings work by default?
  @video_codecs [
    %ExWebRTC.RTPCodecParameters{
      payload_type: 96,
      mime_type: "video/VP8",
      clock_rate: 90_000
    }
  ]

  @audio_codecs [
    %ExWebRTC.RTPCodecParameters{
      payload_type: 111,
      mime_type: "audio/opus",
      clock_rate: 48_000,
      channels: 2
    }
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid gap-4 grid-cols-[1fr_440px] grid-rows-1 h-full pb-4">
      <div class="flex flex-col justify-between gap-4 flex-1">
        <div class="glitch-container-primary flex-1">
          <div class="border-b border-indigo-200 px-8 py-2 flex justify-between items-center gap-4 dark:border-zinc-800">
            <h1 class="font-medium dark:text-neutral-200">Stream details</h1>
            <.dropping class="py-1">
              <div class="flex items-center gap-2 text-xs">
                <.icon name="hero-eye" class="w-4 h-4" />
                {@viewers_count}
              </div>
            </.dropping>
          </div>
          <form phx-submit="stream-config-update" class="flex-1 flex flex-col items-stretch gap-2 p-4">
            <div class="flex gap-2">
              <input
                type="text"
                name="title"
                value={@form_data.title}
                placeholder="Title..."
                class="glitch-input-primary"
                phx-change="update-title"
              />
              <button class="glitch-button-primary self-start">
                Save
              </button>
            </div>
            <textarea
              name="description"
              placeholder="Description..."
              class="glitch-input-primary resize-none"
              phx-change="update-description"
            >{@form_data.description}</textarea>
          </form>
        </div>
        <div class="flex items-stretch justify-stretch *:w-full">
          <Publisher.live_render socket={@socket} publisher={@publisher} />
        </div>
      </div>
      <ChatLive.live_render socket={@socket} id="livechat" role="streamer" timezone={@timezone} />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Glitch.PubSub, "stream_info:viewers")
    end

    connect_params = get_connect_params(socket)

    timezone =
      if connect_params != nil do
        Map.get(connect_params, "timezone", "Etc/UTC")
      else
        "Etc/UTC"
      end

    socket =
      Publisher.attach(socket,
        id: "publisher",
        pubsub: Glitch.PubSub,
        on_connected: &on_connected/1,
        on_disconnected: &on_disconnected/1,
        on_recording_finished: &on_recording_finished/2,
        recordings?: Glitch.FeatureFlags.recordings_enabled(),
        ice_servers: [%{urls: "stun:stun.l.google.com:19302"}],
        video_codecs: @video_codecs,
        audio_codecs: @audio_codecs
      )
      |> assign(:form_data, %{title: "", description: ""})
      |> assign(:page_title, "Streamer Panel")
      |> assign(:viewers_count, StreamViewerLive.get_viewers_count())
      |> assign(:timezone, timezone)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "stream-config-update",
        %{"title" => title, "description" => description},
        socket
      ) do
    Glitch.StreamService.put_stream_metadata(%{title: title, description: description})

    {:noreply, socket}
  end

  def handle_event(
        "update-title",
        %{"title" => title},
        socket
      ) do
    socket =
      socket
      |> assign(:form_data, %{socket.assigns.form_data | title: title})

    {:noreply, socket}
  end

  def handle_event(
        "update-description",
        %{"description" => description},
        socket
      ) do
    socket =
      socket
      |> assign(:form_data, %{socket.assigns.form_data | description: description})

    {:noreply, socket}
  end

  defp on_connected("publisher") do
    Glitch.StreamService.stream_started()
  end

  defp on_disconnected("publisher") do
    Glitch.StreamService.stream_ended()
  end

  defp on_recording_finished("publisher", {:ok, manifest, nil}) do
    metadata = Glitch.StreamService.get_stream_metadata()
    Glitch.RecordingsService.recording_complete(manifest, metadata)
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :viewers_count, StreamViewerLive.get_viewers_count())}
  end
end
