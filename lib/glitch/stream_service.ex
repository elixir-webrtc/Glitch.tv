defmodule Glitch.StreamService do
  @moduledoc false

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def stream_started do
    GenServer.call(__MODULE__, :stream_started)
  end

  def stream_ended do
    GenServer.call(__MODULE__, :stream_ended)
  end

  def get_stream_metadata do
    GenServer.call(__MODULE__, :get_stream_metadata)
  end

  def put_stream_metadata(metadata) do
    GenServer.call(__MODULE__, {:put_stream_metadata, metadata})
  end

  @impl true
  def init(_arg) do
    state = %{
      streaming?: false,
      title: nil,
      description: nil,
      started: nil,
      timer_ref: nil,
      streamer_pid: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:stream_started, {pid, _}, state) do
    started = DateTime.utc_now()
    Phoenix.PubSub.broadcast(Glitch.PubSub, "stream_info:status", {:started, started})
    {:ok, timer_ref} = :timer.send_interval(60_000, self(), :tick)

    state = %{state | streaming?: true, started: started, timer_ref: timer_ref, streamer_pid: pid}
    {:reply, :ok, state}
  end

  def handle_call(:stream_ended, {pid, _}, state) do
    if pid != state.streamer_pid do
      {:reply, :not_streaming, state}
    else
      state = %{state | streaming?: false, started: nil, streamer_pid: nil}
      Phoenix.PubSub.broadcast(Glitch.PubSub, "stream_info:status", :finished)
      :timer.cancel(state.timer_ref)
      {:reply, :ok, state}
    end
  end

  def handle_call(:get_stream_metadata, _from, state) do
    metadata = %{
      title: state.title,
      description: state.description,
      started: state.started,
      streaming?: state.streaming?
    }

    {:reply, metadata, state}
  end

  def handle_call({:put_stream_metadata, metadata}, _from, state) do
    state = %{state | title: metadata.title || "", description: metadata.description || ""}

    Phoenix.PubSub.broadcast(
      Glitch.PubSub,
      "stream_info:status",
      {:changed, {state.title, state.description}}
    )

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    Phoenix.PubSub.broadcast(Glitch.PubSub, "stream_info:status", :tick)
    {:noreply, state}
  end
end
