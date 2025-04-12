defmodule SludgeWeb.StreamViewerLive do
  use SludgeWeb, :live_view

  alias LiveExWebRTC.Player
  alias Phoenix.Presence
  alias Phoenix.Socket.Broadcast
  alias SludgeWeb.ChatLive
  alias SludgeWeb.Presence
  alias SludgeWeb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[
      "grid gap-4 grid-rows-2 lg:grid-rows-1 lg:max-h-full",
      @chat_visible && "lg:grid-cols-[1fr_400px]",
      !@chat_visible && "lg:grid-cols-1"
    ]}>
      <div class="flex flex-col gap-4 justify-stretch w-full h-full overflow-y-auto">
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
              <span class="sludge-dropping-featured-text">
                {@stream_duration} minutes ago
              </span>
            <% else %>
              Stream is offline
            <% end %>
          </.dropping>
          <.dropping>
            <span class="sludge-dropping-featured-text">
              {@viewers_count} viewers
            </span>
          </.dropping>
          <.share_button />
        </div>
        <div id="stream-viewer-description" class="dark:text-neutral-400 break-all">
          {raw(@stream_metadata.description)}
        </div>
      </div>
      <div :if={@chat_visible} class="pb-4 relative">
        <div class="h-full *:h-full">
          <ChatLive.live_render socket={@socket} id="livechat" role="user" />
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
    <p class="sludge-live-dropping-container">
      live
    </p>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Sludge.PubSub, "stream_info:status")
      Phoenix.PubSub.subscribe(Sludge.PubSub, "stream_info:viewers")
      {:ok, _ref} = Presence.track(self(), "stream_info:viewers", inspect(self()), %{})
    end

    metadata = Sludge.StreamService.get_stream_metadata()

    socket =
      Player.attach(socket,
        id: "player",
        publisher_id: "publisher",
        pubsub: Sludge.PubSub,
        ice_servers: [%{urls: "stun:stun.l.google.com:19302"}]
        # ice_ip_filter: Application.get_env(:live_broadcaster, :ice_ip_filter)
      )
      |> assign(:page_title, "Stream")
      |> assign(:stream_metadata, metadata_to_html(metadata))
      |> assign(:viewers_count, get_viewers_count())
      |> assign(:stream_duration, measure_duration(metadata.started))
      |> assign(:chat_visible, true)

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
      | title: Utils.to_html(title),
        description: Utils.to_html(description)
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
      | title: Utils.to_html(metadata.title),
        description: Utils.to_html(metadata.description)
    }
  end
end
