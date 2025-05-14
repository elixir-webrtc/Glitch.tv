defmodule GlitchWeb.StreamViewerLive do
  alias Glitch.FeatureFlags
  use GlitchWeb, :live_view

  alias LiveExWebRTC.Player
  alias Phoenix.Presence
  alias Phoenix.Socket.Broadcast
  alias GlitchWeb.ChatLive
  alias GlitchWeb.Presence
  alias GlitchWeb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[
      "grid gap-4 grid-rows-[auto_512px] lg:grid-rows-1 lg:h-full",
      @chat_visible && "lg:grid-cols-[1fr_400px]",
      !@chat_visible && "lg:grid-cols-1"
    ]}>
      <div class="flex flex-col gap-4 justify-stretch w-full h-full overflow-y-auto pb-8">
        <div class={[
          "relative grid grid-cols-1 grid-rows-1",
          @chat_visible && "lg:grid-rows-[70vh]",
          !@chat_visible && "lg:grid-rows-[80vh]"
        ]}>
          <Player.live_render
            socket={@socket}
            player={@player}
            class="w-full h-full"
            video_class="rounded-lg bg-black"
          />
          <img
            src="/images/swm-white-logo.svg"
            class={[
              "absolute top-6 pointer-events-none",
              @chat_visible && "right-6",
              !@chat_visible && "right-14"
            ]}
          />
          <button
            :if={!@chat_visible}
            phx-click="toggle_chat"
            class="absolute right-3 top-5 z-20 hidden lg:block hover:bg-stone-700 p-2 rounded-lg"
          >
            <.icon name="hero-chevron-left" class="text-white w-4 h-4 block" />
          </button>
        </div>
        <div class="flex gap-3 items-center justify-start">
          <%= if @stream_metadata.streaming? do %>
            <.live_dropping />
          <% end %>
          <div
            id="stream-viewer-title"
            class="text-2xl line-clamp-3 lg:line-clamp-2 dark:text-neutral-200 break-all"
          >
            {raw(@stream_metadata.title)}
          </div>
        </div>
        <div class="flex flex-wrap gap-4 text-sm">
          <.dropping>
            <%= if @stream_metadata.streaming? do %>
              Started:&nbsp;
              <span class="glitch-dropping-featured-text">
                {@stream_duration} minutes ago
              </span>
            <% else %>
              Stream is offline
            <% end %>
          </.dropping>
          <.dropping>
            <span class="glitch-dropping-featured-text">
              {@viewers_count} viewers
            </span>
          </.dropping>
          <.share_button :if={FeatureFlags.share_button_enabled()} />
        </div>
        <div class="max-h-[128px] lg:max-h-none overflow-auto lg:overflow-visible dark:text-neutral-400 break-all glitch-markdown">
          {raw(@stream_metadata.description)}
        </div>
      </div>
      <div class={["pb-4 relative", !@chat_visible && "hidden"]}>
        <div class="h-full *:h-full">
          <ChatLive.live_render socket={@socket} id="livechat" role="user" timezone={@timezone} />
        </div>
        <button
          phx-click="toggle_chat"
          class="hidden lg:block absolute top-[13px] left-4 z-10 hover:bg-stone-200 dark:hover:bg-stone-800 p-2 rounded-lg"
        >
          <.icon name="hero-chevron-right" class="w-4 h-4 block dark:text-neutral-400" />
        </button>
      </div>
    </div>
    """
  end

  defp live_dropping(assigns) do
    ~H"""
    <p class="glitch-live-dropping-container">
      live
    </p>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Glitch.PubSub, "stream_info:status")
      Phoenix.PubSub.subscribe(Glitch.PubSub, "stream_info:viewers")
      {:ok, _ref} = Presence.track(self(), "stream_info:viewers", inspect(self()), %{})
    end

    metadata = Glitch.StreamService.get_stream_metadata()

    connect_params = get_connect_params(socket)

    timezone =
      if connect_params != nil do
        Map.get(connect_params, "timezone", "Etc/UTC")
      else
        "Etc/UTC"
      end

    socket =
      Player.attach(socket,
        id: "player",
        publisher_id: "publisher",
        pubsub: Glitch.PubSub,
        ice_servers: [%{urls: "stun:stun.l.google.com:19302"}]
      )
      |> assign(:page_title, "Stream")
      |> assign(:stream_metadata, metadata_to_html(metadata))
      |> assign(:viewers_count, get_viewers_count())
      |> assign(:stream_duration, measure_duration(metadata.started))
      |> assign(:chat_visible, true)
      |> assign(:timezone, timezone)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:started, started}, socket) do
    metadata = %{socket.assigns.stream_metadata | streaming?: true, started: started}
    {:noreply, assign(socket, :stream_metadata, metadata)}
  end

  def handle_info({:changed, {title, description}}, socket) do
    metadata = %{
      socket.assigns.stream_metadata
      | title: Utils.to_html_description(title),
        description: Utils.to_html_description(description)
    }

    {:noreply, assign(socket, :stream_metadata, metadata)}
  end

  def handle_info(:finished, socket) do
    metadata = %{socket.assigns.stream_metadata | streaming?: false, started: nil}
    {:noreply, assign(socket, :stream_metadata, metadata)}
  end

  def handle_info(:tick, socket) do
    socket =
      socket
      |> assign(
        :stream_duration,
        measure_duration(socket.assigns.stream_metadata.started)
      )

    {:noreply, socket}
  end

  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :viewers_count, get_viewers_count())}
  end

  @impl true
  def handle_event("toggle_chat", _, socket) do
    socket = assign(socket, chat_visible: !socket.assigns.chat_visible)

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def get_viewers_count() do
    map_size(Presence.list("stream_info:viewers"))
  end

  defp measure_duration(started_timestamp) do
    case started_timestamp do
      nil ->
        0

      t ->
        DateTime.utc_now()
        |> DateTime.diff(t, :minute)
    end
  end

  defp metadata_to_html(metadata) do
    %{
      metadata
      | title: Utils.to_html_description(metadata.title),
        description: Utils.to_html_description(metadata.description)
    }
  end
end
