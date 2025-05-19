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
    <div class="h-full *:h-full">
      {render_chat(assigns)}
    </div>
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
      <div class={["flex-grow h-[0px] *:h-full", @current_tab != "chat" && "hidden"]}>
        {render_chat(assigns)}
      </div>
      {render_reported(assigns)}
    </div>
    """
  end

  def render_chat(assigns) do
    assigns =
      assigns
      |> assign(:settings, build_settings(assigns))

    ~H"""
    <div
      id="glitch_chat"
      phx-hook="ChatHook"
      data-settings={@settings}
      phx-update="ignore"
    >
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
            {raw(GlitchWeb.Utils.to_html_chat(msg.body))}
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

    messages =
      Messages.list_last_50_messages()
      |> Enum.map(fn msg ->
        Map.put(msg, :body, GlitchWeb.Utils.to_html_chat(msg.body))
      end)

    socket =
      socket
      |> assign(:last_msg_timestamp, System.monotonic_time(:millisecond))
      |> assign(messages: messages)
      |> assign(role: session["role"])
      |> assign(current_tab: "chat")
      |> assign(max_msg_length: 500, max_nickname_length: 25)
      |> assign(slow_mode_delay_s: Application.fetch_env!(:glitch, :slow_mode_delay_s))
      |> assign(timezone: session["timezone"])

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_msg, msg}, socket) do
    messages = socket.assigns.messages ++ [msg]

    socket =
      socket
      |> push_event("new-message", msg)
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:msg_flagged, flagged_message_id}, socket) do
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
      |> push_event("flagged-message", %{"id" => flagged_message_id})
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  def handle_info({:delete_msg, message_id}, socket) do
    message_id =
      cond do
        is_integer(message_id) -> message_id
        true -> String.to_integer(message_id)
      end

    messages =
      socket.assigns.messages
      |> Enum.filter(fn message -> message.id != message_id end)

    socket =
      socket
      |> push_event("deleted-message", %{"id" => message_id})
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  def handle_info({:ignore_flag, message_id}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.map(fn message ->
        if message.id == message_id do
          Map.put(message, :flagged, false)
        else
          message
        end
      end)

    socket =
      socket
      |> push_event("unflagged-message", %{"id" => message_id})
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

    {:noreply, socket}
  end

  def handle_event("select-tab", %{"tab" => tab}, socket) do
    socket = assign(socket, :current_tab, tab)

    {:noreply, socket}
  end

  def handle_event("delete_message", %{"message-id" => message_id}, socket) do
    message_id =
      cond do
        is_integer(message_id) -> message_id
        true -> String.to_integer(message_id)
      end

    {:ok, _} = Messages.delete_message(%Message{id: message_id})

    Phoenix.PubSub.broadcast(Glitch.PubSub, "chatroom", {:delete_msg, message_id})

    {:noreply, socket}
  end

  def handle_event("ignore_flag", %{"message-id" => messageId}, socket) do
    messageId = String.to_integer(messageId)

    message =
      socket.assigns.messages
      |> Enum.find(fn message ->
        message.id == messageId
      end)

    {:ok, _} =
      Messages.update_message(message, %{flagged: false})

    Phoenix.PubSub.broadcast(Glitch.PubSub, "chatroom", {:ignore_flag, messageId})

    {:noreply, socket}
  end

  def handle_event("submit-form", %{"body" => body, "author" => author}, socket) do
    role = socket.assigns.role

    now = System.monotonic_time(:millisecond)
    time_elapsed = now - socket.assigns.last_msg_timestamp
    slow_mode_delay = socket.assigns.slow_mode_delay_s * 1000

    message_length = body |> GlitchWeb.Utils.to_text() |> String.length()

    cond do
      message_length > 0 && (role == "streamer" || time_elapsed >= slow_mode_delay) ->
        msg = send_message(body, author)

        {
          :reply,
          %{"action" => "done", "message" => msg},
          assign(socket, msg_body: nil, last_msg_timestamp: now)
        }

      time_elapsed >= slow_mode_delay ->
        {:reply, %{"action" => "delayed", "delay" => slow_mode_delay - time_elapsed}, socket}

      true ->
        {
          :reply,
          %{"action" => "delayed", "delay" => slow_mode_delay - time_elapsed},
          socket
        }
    end
  end

  def handle_event("flag-message", %{"message-id" => flagged_message_id}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.map(fn message ->
        if message.id == flagged_message_id do
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

    msg = Map.put(msg, :body, GlitchWeb.Utils.to_html_chat(msg.body))

    Phoenix.PubSub.broadcast(Glitch.PubSub, "chatroom", {:new_msg, msg})

    msg
  end

  defp build_settings(assigns) do
    Jason.encode!(%{
      messages: assigns.messages,
      slowModeSec: assigns.slow_mode_delay_s,
      maxBodyLength: assigns.max_msg_length,
      maxAuthorLength: assigns.max_nickname_length,
      role: assigns.role
    })
  end
end
