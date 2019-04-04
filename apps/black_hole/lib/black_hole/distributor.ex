defmodule BlackHole.Distributor do
  use GenServer

  alias BlackHole.Websocket
  alias Queue.Pusher

  ## Client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def send_to_socket(msg) do
    GenServer.cast(__MODULE__, { :send, msg })
  end

  ## Server Callbacks
  def init(_arg) do
    socket = Websocket.connect

    spawn(__MODULE__, :puller, [socket])

    {:ok, socket}
  end

  def handle_cast({:send, msg}, socket) do
    socket |> Websocket.push(msg)

    { :noreply, socket}
  end

  def puller(socket) do
    case socket |> Websocket.pull do
      { :pass, data } -> push_on_queue(data)
      { :skip, _ } -> :ok
    end

    puller(socket)
  end

  def push_on_queue(data) do
    Pusher.add(data) 
  end
end