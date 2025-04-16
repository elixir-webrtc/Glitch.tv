defmodule Glitch.MessagesService do
  @moduledoc false
  alias Glitch.Messages

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(period_ms) do
    schedule_removing_stale_messages(period_ms)

    {:ok, period_ms}
  end

  @impl true
  def handle_info(:remove_stale_messages, period_ms) do
    Messages.delete_stale_messages()

    schedule_removing_stale_messages(period_ms)

    {:noreply, period_ms}
  end

  defp schedule_removing_stale_messages(period_ms) do
    Process.send_after(self(), :remove_stale_messages, period_ms)
  end
end
