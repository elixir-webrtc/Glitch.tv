defmodule GlitchWeb.ChatLive do
  alias Glitch.Messages
  alias Glitch.Messages.Message
  use GlitchWeb, :live_view

  attr(:timezone, :string, required: true)
  attr(:socket, Phoenix.LiveView.Socket, required: true, doc: "Parent live view socket")
  attr(:role, :string, required: true, doc: "Streamer or user")
  attr(:id, :string, required: true, doc: "Component id")

  def live_render(assigns) do
    ~H"""
    {live_render(@socket, __MODULE__, id: @id, session: %{"role" => @role, "timezone" => @timezone})}
    """
  end

  @impl true
  def render(%{role: "user"} = assigns) do
    ~H"""
    {render_chat(assigns)}
    """
  end

  def render(%{role: "streamer"} = assigns) do
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
        "justify-between flex-col",
        @current_tab == "chat" && "flex",
        @current_tab != "chat" && "hidden",
        @role == "streamer" && "h-[0px] flex-grow",
        @role == "user" && "h-full rounded-lg border border-indigo-200 dark:border-zinc-800"
      ]}
      id="glitch_chat"
    >
      <div
        :if={@role == "user"}
        class="py-4 px-8 border-b border-indigo-200 text-center dark:border-zinc-800 dark:text-neutral-400 hidden lg:block"
      >
        Chat
      </div>
      <div class={[
        @role == "user" &&
          "p-2 text-center text-xs border-b-[1px] border-indigo-200 dark:border-zinc-800 dark:text-neutral-400",
        @role != "user" && "hidden"
      ]}>
        This is not an official ElixirConf EU chat, so if you have any questions for the speakers, please ask them under the SwapCard stream.
      </div>
      <ul class="overflow-y-auto flex-grow flex flex-col" phx-hook="ScrollDownHook" id="message_box">
        <li
          :for={msg <- @messages}
          id={"#{msg.id}-msg"}
          class={[
            "group flex flex-col gap-1 px-6 py-4 relative",
            msg.flagged && @role == "user" &&
              "bg-red-100 hover:bg-red-200 dark:bg-red-900 dark:hover:bg-red-800",
            !msg.flagged && "hover:bg-stone-100 dark:hover:bg-stone-800"
          ]}
        >
          <div class="flex gap-4 justify-between items-center">
            <div class="flex gap-4 items-center">
              <p class="text-indigo-800 text-sm text-medium dark:text-indigo-400">
                {msg.author}
              </p>
              <.tooltip
                tooltip={
                  Calendar.strftime(
                    DateTime.shift_zone!(msg.inserted_at, @timezone),
                    "%d %b %Y %H:%M:%S"
                  )
                }
                id={"#{msg.id}-time"}
              >
                <p class="text-xs text-neutral-500 m-0">
                  {Calendar.strftime(DateTime.shift_zone!(msg.inserted_at, @timezone), "%H:%M")}
                </p>
              </.tooltip>
            </div>
            <div class={[msg.flagged && "opacity-0"]}>
              <.tooltip tooltip="Report" id={"#{msg.id}-report"}>
                <button
                  class={[
                    "rounded-full flex items-center justify-center p-2",
                    msg.flagged && "hover:bg-red-300",
                    !msg.flagged && "hover:bg-stone-200 dark:hover:bg-stone-700",
                    @role == "streamer" && "hidden"
                  ]}
                  phx-click="flag-message"
                  phx-value-message-id={msg.id}
                  disabled={msg.flagged}
                >
                  <.icon name="hero-flag" class="w-4 h-4 text-red-400" />
                </button>
              </.tooltip>
            </div>
          </div>
          <div class="dark:text-neutral-400 break-all glitch-markdown">
            {raw(GlitchWeb.Utils.to_html(msg.body))}
          </div>
          <div class={[
            "hidden gap-4 items-center *:flex-1 mt-4",
            @role == "streamer" && "group-hover:flex"
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
            <div class="flex justify-between min-h-[16px] mt-[-14px] mb-[2px]">
              <div class={[
                @role == "streamer" && "hidden",
                "text-xs",
                @highlight_slow_mode && "text-rose-600",
                !@highlight_slow_mode &&
                  "text-neutral-400 dark:text-neutral-700"
              ]}>
                Slow Mode {@slow_mode_delay_s}s
              </div>
              <%!-- spacer to preserve layout with streamer role --%>
              <div></div>
              <div class={[
                "text-xs text-neutral-400 dark:text-neutral-700",
                String.length(@msg_body || "") < @max_msg_length - 50 && "hidden",
                String.length(@msg_body || "") == @max_msg_length &&
                  "text-rose-600 dark:text-rose-600"
              ]}>
                {String.length(@msg_body || "")}/{@max_msg_length}
              </div>
            </div>
            <textarea
              class="glitch-input-primary resize-none h-[96px] w-full dark:text-neutral-400"
              placeholder="Your message"
              maxlength={@max_msg_length}
              name="body"
              disabled={not @joined}
              id="message_body"
              phx-hook="MessageBodyHook"
              data-slow-mode={to_string(@highlight_slow_mode)}
            >{@msg_body}</textarea>
          </div>
          <div class="relative">
            <button
              type="button"
              class="border border-indigo-200 rounded-lg px-2 py-1 disabled:opacity-50 dark:text-neutral-400 dark:border-zinc-800 dark:bg-zinc-800"
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
              class="glitch-input-primary px-4 py-2"
              placeholder="Your nickname"
              maxlength={@max_nickname_length}
              name="author"
              value={@author}
              disabled={@joined}
            />
            <%= if not @joined do %>
              <div class={[
                "absolute bottom-[-18px] right-0 text-xs w-full text-neutral-400 dark:text-neutral-700",
                String.length(@author || "") < @max_nickname_length - 5 && "hidden",
                String.length(@author || "") == @max_nickname_length &&
                  "text-rose-600 dark:text-rose-600"
              ]}>
                {String.length(@author || "")}/{@max_nickname_length}
              </div>
            <% end %>
          </div>
          <button
            type="submit"
            class="glitch-button-primary"
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
        "h-[0px] flex-grow justify-between flex-col",
        @current_tab == "reported" && "flex",
        @current_tab != "reported" && "hidden"
      ]}
      id="glitch_reported"
    >
      <ul class="overflow-y-auto flex-grow flex flex-col">
        <li
          :for={msg <- Enum.filter(@messages, fn m -> m.flagged end)}
          id={"#{msg.id}-reported"}
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
              {Calendar.strftime(
                DateTime.shift_zone!(msg.inserted_at, @timezone),
                "%d %b %Y %H:%M:%S"
              )}
            </p>
          </div>
          <div class="dark:text-neutral-400 break-all glitch-markdown">
            {raw(GlitchWeb.Utils.to_html(msg.body))}
          </div>
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

    messages = Messages.list_last_50_messages()

    socket =
      socket
      |> assign(:last_msg_timestamp, System.monotonic_time(:millisecond))
      |> assign(messages: messages)
      |> assign(msg_body: nil, author: nil)
      |> assign(role: session["role"])
      |> assign(current_tab: "chat")
      |> assign(max_msg_length: 500, max_nickname_length: 25)
      |> assign(slow_mode_delay_s: Application.fetch_env!(:glitch, :slow_mode_delay_s))
      |> assign(highlight_slow_mode: false)
      |> assign(joined: false)
      |> assign(show_emoji_overlay: false)
      |> assign(timezone: session["timezone"])

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_msg, msg}, socket) do
    messages = socket.assigns.messages ++ [msg]

    socket = push_event(socket, "new-message", %{})

    {:noreply, assign(socket, :messages, messages)}
  end

  def handle_info({:msg_flagged, flagged_message_id}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.map(fn message ->
        if to_string(message.id) == flagged_message_id do
          Map.put(message, :flagged, true)
        else
          message
        end
      end)

    socket =
      socket
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  def handle_info({:delete_msg, message_id}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.filter(fn message -> message.id != String.to_integer(message_id) end)

    socket =
      socket
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  def handle_info({:ignore_flag, message_id}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.map(fn message ->
        if message.id == String.to_integer(message_id) do
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

  def handle_info(:reset_slow_mode_highlight, socket) do
    {:noreply, assign(socket, highlight_slow_mode: false)}
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

  def handle_event("toggle-emoji-overlay", _, socket) do
    socket = assign(socket, :show_emoji_overlay, !socket.assigns.show_emoji_overlay)

    {:noreply, socket}
  end

  def handle_event("hide-emoji-overlay", _, socket) do
    socket = assign(socket, :show_emoji_overlay, false)

    {:noreply, socket}
  end

  def handle_event("select-tab", %{"tab" => tab}, socket) do
    socket = assign(socket, :current_tab, tab)

    {:noreply, socket}
  end

  def handle_event("delete_message", %{"message-id" => messageId}, socket) do
    {:ok, _} = Messages.delete_message(%Message{id: String.to_integer(messageId)})

    Phoenix.PubSub.broadcast(Glitch.PubSub, "chatroom", {:delete_msg, messageId})

    {:noreply, socket}
  end

  def handle_event("ignore_flag", %{"message-id" => messageId}, socket) do
    message =
      socket.assigns.messages
      |> Enum.find(fn message ->
        message.id == String.to_integer(messageId)
      end)

    {:ok, _} =
      Messages.update_message(message, %{flagged: false})

    Phoenix.PubSub.broadcast(Glitch.PubSub, "chatroom", {:ignore_flag, messageId})

    {:noreply, socket}
  end

  def handle_event("validate-form", %{"author" => author}, socket) do
    {:noreply, assign(socket, author: author)}
  end

  def handle_event("validate-form", %{"body" => body}, socket) do
    {:noreply, assign(socket, msg_body: body)}
  end

  def handle_event("submit-form", %{"body" => body}, socket) do
    now = System.monotonic_time(:millisecond)
    text = GlitchWeb.Utils.to_text(body)
    role = socket.assigns.role
    time_elapsed = now - socket.assigns.last_msg_timestamp
    slow_mode_delay = socket.assigns.slow_mode_delay_s * 1000

    if String.length(text) > 0 &&
         (role == "streamer" ||
            time_elapsed >= slow_mode_delay) do
      send_message(body, socket.assigns.author)
      {:noreply, assign(socket, msg_body: nil, last_msg_timestamp: now)}
    else
      if socket.assigns.highlight_slow_mode == true do
        {:noreply, socket}
      end

      Process.send_after(
        self(),
        :reset_slow_mode_highlight,
        slow_mode_delay - time_elapsed
      )

      {:noreply, assign(socket, highlight_slow_mode: true)}
    end
  end

  def handle_event("submit-form", %{"author" => _}, socket) do
    {:noreply, assign(socket, joined: true)}
  end

  def handle_event("flag-message", %{"message-id" => flagged_message_id}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.map(fn message ->
        if to_string(message.id) == flagged_message_id do
          {:ok, _} = Messages.update_message(message, %{flagged: true})

          Map.put(message, :flagged, true)
        else
          message
        end
      end)

    socket =
      socket
      |> assign(:messages, messages)

    Phoenix.PubSub.broadcast(Glitch.PubSub, "chatroom", {:msg_flagged, flagged_message_id})

    {:noreply, socket}
  end

  defp subscribe() do
    Phoenix.PubSub.subscribe(Glitch.PubSub, "chatroom")
  end

  defp send_message(body, author) do
    {:ok, timestamp} = DateTime.now("Etc/UTC")

    message_attr = %{
      author: author,
      body: body,
      timestamp: timestamp,
      flagged: false
    }

    {:ok, msg} = Messages.create_message(message_attr)

    Phoenix.PubSub.broadcast(Glitch.PubSub, "chatroom", {:new_msg, msg})
  end
end
