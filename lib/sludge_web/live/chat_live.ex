defmodule SludgeWeb.ChatLive do
  use SludgeWeb, :live_view

  attr(:socket, Phoenix.LiveView.Socket, required: true, doc: "Parent live view socket")
  attr(:role, :string, required: true, doc: "Admin or user")
  attr(:id, :string, required: true, doc: "Component id")

  def live_render(assigns) do
    ~H"""
    {live_render(@socket, __MODULE__, id: @id, session: %{"role" => @role})}
    """
  end

  @impl true
  def render(%{role: "user"} = assigns) do
    ~H"""
    {render_chat(assigns)}
    """
  end

  def render(%{role: "admin"} = assigns) do
    ~H"""
    <div class="rounded-lg border border-indigo-200 flex flex-col h-full dark:border-zinc-800">
      <ul class="flex *:flex-1 items-center border-b border-indigo-200 dark:border-zinc-800">
        <li>
          <button
            phx-click="select-tab"
            phx-value-tab="chat"
            class={[
              "w-full h-full px-4 py-3 rounded-tl-[7px] text-center text-indigo-700 text-indigo-800 text-sm hover:text-white hover:bg-indigo-900 dark:text-white",
              @current_tab == "chat" &&
                "text-white bg-indigo-800 dark:hover:bg-indigo-700"
            ]}
          >
            Chat
          </button>
        </li>
        <li>
          <button
            phx-click="select-tab"
            phx-value-tab="reported"
            class={[
              "w-full h-full px-4 py-3 rounded-tr-[7px] text-center text-indigo-700 text-indigo-800 text-sm hover:text-white hover:bg-indigo-900 dark:text-white",
              @current_tab == "reported" &&
                "text-white bg-indigo-800 dark:hover:bg-indigo-700"
            ]}
          >
            Reported ({Enum.count(@messages, fn x -> x.flagged end)})
          </button>
        </li>
      </ul>
      {render_chat(assigns)}
      {render_reported(assigns)}
    </div>
    """
  end

  def render_chat(assigns) do
    ~H"""
    <div
      class={[
        "h-full justify-between flex-col",
        @current_tab == "chat" && "flex",
        @current_tab != "chat" && "hidden",
        @role == "admin" && "",
        @role == "user" && "rounded-lg border border-indigo-200 dark:border-zinc-800"
      ]}
      id="sludge_chat"
    >
      <div class={
        (@role == "user" &&
           "p-2 text-center text-xs border-b-[1px] border-indigo-200 dark:border-zinc-800 dark:text-neutral-400") ||
          "hidden"
      }>
        This is not an official ElixirConf EU chat, so if you have any questions for the speakers, please ask them under the SwapCard stream.
      </div>
      <ul class="overflow-y-auto flex-grow flex flex-col" phx-hook="ScrollDownHook" id="message_box">
        <li
          :for={msg <- @messages}
          id={msg.id <> "-msg"}
          class={[
            "group flex flex-col gap-1 px-6 py-4 relative",
            msg.flagged && @role == "user" &&
              "bg-red-100 hover:bg-red-200 dark:bg-red-900 dark:hover:bg-red-800",
            !msg.flagged && "hover:bg-stone-100 dark:hover:bg-stone-800",
            @role == "user" && "first:rounded-t-[7px]"
          ]}
        >
          <div class="flex gap-4 justify-between items-center">
            <p class="text-indigo-800 text-sm text-medium dark:text-indigo-400">
              {msg.author}
            </p>
            <p class="text-xs text-neutral-500">
              {Calendar.strftime(msg.timestamp, "%d %b %Y %H:%M:%S")}
            </p>
          </div>
          <div class="dark:text-neutral-400">
            {raw(SludgeWeb.Utils.to_html(msg.body))}
          </div>
          <div class="absolute right-6 bottom-2">
            <.tooltip tooltip={if msg.flagged, do: "Unreport", else: "Report"}>
              <button
                class={[
                  "rounded-full flex items-center justify-center p-2",
                  msg.flagged && "hover:bg-red-300",
                  !msg.flagged && "hover:bg-stone-200 dark:hover:bg-stone-700",
                  @role == "admin" && "hidden"
                ]}
                phx-click="flag-message"
                phx-value-message-id={msg.id}
              >
                <.icon name="hero-flag" class="w-4 h-4 text-red-400" />
              </button>
            </.tooltip>
          </div>
          <div class={[
            "hidden gap-4 items-center *:flex-1 mt-4",
            @role == "admin" && "group-hover:flex"
          ]}>
            <button
              class="bg-red-600 text-white rounded-lg py-1"
              phx-click="delete_message"
              phx-value-message-id={msg.id}
            >
              Delete
            </button>
          </div>
        </li>
      </ul>
      <form
        phx-change="validate-form"
        phx-submit="submit-form"
        class="border-t border-indigo-200 p-6 dark:border-zinc-800"
      >
        <div class="flex items-end gap-2 relative mb-2">
          <div class="flex flex-col relative w-full">
            <div class={
              (String.length(@msg_body || "") == @max_msg_length &&
                 "absolute top-[-18px] right-[2px] text-xs w-full text-right text-rose-600 dark:text-rose-600") ||
                (String.length(@msg_body || "") > @max_msg_length - 50 &&
                   "absolute top-[-18px] right-[2px] text-xs w-full text-right text-neutral-400 dark:text-neutral-700") ||
                "hidden"
            }>
              {String.length(@msg_body || "")}/{@max_msg_length}
            </div>
            <textarea
              class="sludge-input-primary resize-none h-[96px] w-full dark:text-neutral-400"
              placeholder="Your message"
              maxlength={@max_msg_length}
              name="body"
              disabled={not @joined}
            >{@msg_body}</textarea>
          </div>
          <div class="relative">
            <button
              type="button"
              class="border border-indigo-200 rounded-lg px-2 py-1 disabled:opacity-50 dark:text-neutral-400 dark:border-none dark:bg-zinc-800"
              phx-click="toggle-emoji-overlay"
              disabled={not @joined}
            >
              <.icon name="hero-face-smile" />
            </button>

            <div
              class={[
                "absolute bottom-[calc(100%+4px)] right-0",
                !@show_emoji_overlay && "hidden"
              ]}
              id="emoji-picker-container"
              phx-hook="EmojiPickerContainerHook"
            >
              <emoji-picker class="light dark:hidden"></emoji-picker>
              <emoji-picker class="hidden dark:block dark"></emoji-picker>
            </div>
          </div>
        </div>
        <div class="flex flex-col sm:flex-row gap-2 mt-2">
          <div class="flex flex-1 relative">
            <input
              class="sludge-input-primary px-4 py-2 dark:text-neutral-400"
              placeholder="Your nickname"
              maxlength={@max_nickname_length}
              name="author"
              value={@author}
              disabled={@joined}
            />
            <%= if not @joined do %>
              <div class={
                (String.length(@author || "") == @max_nickname_length &&
                   "absolute bottom-[-18px] right-0 text-xs w-full text-rose-600 dark:text-rose-600") ||
                  (String.length(@author || "") > @max_nickname_length - 5 &&
                     "absolute bottom-[-18px] right-0 text-xs w-full text-neutral-400 dark:text-neutral-700") ||
                  "hidden"
              }>
                {String.length(@author || "")}/{@max_nickname_length}
              </div>
            <% end %>
          </div>
          <button
            type="submit"
            class="sludge-button-primary"
            disabled={String.length(@author || "") == 0}
          >
            <%= if not @joined do %>
              Join
            <% else %>
              Send
            <% end %>
          </button>
        </div>
      </form>
    </div>
    """
  end

  def render_reported(assigns) do
    ~H"""
    <div
      class={[
        "h-full justify-between flex-col",
        @current_tab == "reported" && "flex",
        @current_tab != "reported" && "hidden"
      ]}
      id="sludge_reported"
    >
      <ul class="overflow-y-auto flex-grow flex flex-col">
        <li
          :for={msg <- Enum.filter(@messages, fn m -> m.flagged end)}
          id={msg.id <> "-reported"}
          class={[
            "flex flex-col gap-1 px-6 py-4 relative hover:bg-stone-100 dark:hover:bg-stone-800",
            @role == "user" && "first:rounded-t-[7px]"
          ]}
        >
          <div class="flex gap-4 justify-between items-center">
            <p class="text-indigo-800 text-sm text-medium dark:text-indigo-400">
              {msg.author}
            </p>
            <p class="text-xs text-neutral-500">
              {Calendar.strftime(msg.timestamp, "%d %b %Y %H:%M:%S")}
            </p>
          </div>
          <p class="dark:text-neutral-400">
            {msg.body}
          </p>
          <div class="flex gap-4 items-center *:flex-1 mt-4">
            <button
              class="bg-red-600 text-white rounded-lg py-1"
              phx-click="delete_message"
              phx-value-message-id={msg.id}
            >
              Delete
            </button>
            <button
              class="bg-gray-600 text-white rounded-lg py-1"
              phx-click="ignore_flag"
              phx-value-message-id={msg.id}
            >
              Ignore
            </button>
          </div>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      subscribe()
    end

    socket =
      socket
      |> assign(:messages, [])
      |> assign(msg_body: nil, author: nil, next_msg_id: 0)
      |> assign(role: session["role"])
      |> assign(current_tab: "chat")
      |> assign(max_msg_length: 500, max_nickname_length: 25)
      |> assign(joined: false)
      |> assign(show_emoji_overlay: false)

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_msg, msg}, socket) do
    messages = socket.assigns.messages ++ [msg]

    {:noreply, assign(socket, :messages, messages)}
  end

  def handle_info({:msg_flagged, flagged_message_id}, socket) do
    if socket.assigns.role == "admin" do
      messages =
        socket.assigns.messages
        |> Enum.map(fn message ->
          if message.id == flagged_message_id do
            Map.put(message, :flagged, true)
          else
            message
          end
        end)

      socket =
        socket
        |> assign(:messages, messages)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:delete_msg, messageId}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.filter(fn message -> message.id != messageId end)

    socket =
      socket
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:ignore_flag, messageId}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.map(fn message ->
        if message.id == messageId do
          Map.put(message, :flagged, false)
        else
          message
        end
      end)

    socket =
      socket
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  @impl true
  def handle_event("append_emoji", %{"emoji" => emoji}, socket) do
    msg_body =
      if socket.assigns.msg_body != nil do
        socket.assigns.msg_body <> emoji
      else
        emoji
      end

    socket =
      socket
      |> assign(msg_body: msg_body)
      |> assign(show_emoji_overlay: false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle-emoji-overlay", _, socket) do
    socket = assign(socket, :show_emoji_overlay, !socket.assigns.show_emoji_overlay)

    {:noreply, socket}
  end

  @impl true
  def handle_event("hide-emoji-overlay", _, socket) do
    socket = assign(socket, :show_emoji_overlay, false)

    {:noreply, socket}
  end

  def handle_event("select-tab", %{"tab" => tab}, socket) do
    socket = assign(socket, :current_tab, tab)

    {:noreply, socket}
  end

  def handle_event("delete_message", %{"message-id" => messageId}, socket) do
    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:delete_msg, messageId})

    {:noreply, socket}
  end

  def handle_event("ignore_flag", %{"message-id" => messageId}, socket) do
    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:ignore_flag, messageId})

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate-form", %{"author" => author}, socket) do
    {:noreply, assign(socket, author: author)}
  end

  def handle_event("validate-form", %{"body" => body}, socket) do
    {:noreply, assign(socket, msg_body: body)}
  end

  def handle_event("submit-form", %{"body" => body}, socket) do
    if body != "" do
      id = socket.assigns.next_msg_id
      send_message(body, socket.assigns.author, id)
      {:noreply, assign(socket, msg_body: nil, next_msg_id: id + 1)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("submit-form", %{"author" => _}, socket) do
    {:noreply, assign(socket, joined: true)}
  end

  def handle_event("flag-message", %{"message-id" => flagged_message_id}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.map(fn message ->
        if message.id == flagged_message_id do
          Map.put(message, :flagged, true)
        else
          message
        end
      end)

    socket =
      socket
      |> assign(:messages, messages)

    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:msg_flagged, flagged_message_id})

    {:noreply, socket}
  end

  defp subscribe() do
    Phoenix.PubSub.subscribe(Sludge.PubSub, "chatroom")
  end

  defp send_message(body, author, id) do
    {:ok, timestamp} = DateTime.now("Etc/UTC")

    msg = %{
      author: author,
      body: body,
      id: "#{author}:#{id}",
      timestamp: timestamp,
      flagged: false
    }

    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:new_msg, msg})
  end
end
