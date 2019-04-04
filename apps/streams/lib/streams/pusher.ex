defmodule Streams.Pusher do
  use GenServer
  use AMQP

  @exchange  "streams_exchange"

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_opts) do
    new_connection()
  end

  def add(msg) do
    GenServer.cast(__MODULE__, { :put, msg })
  end

  def handle_cast({:put, msg}, chan) do
    AMQP.Basic.publish chan, @exchange, "", msg
    { :noreply, chan }
  end


  defp new_connection do
    case Connection.open("amqp://guest:guest@localhost") do
      {:ok, conn} ->
        {:ok, chan} = Channel.open(conn)

        Process.monitor(conn.pid)

        Basic.qos(chan, prefetch_count: 10)
        {:ok, chan}
  
      {:error, _} ->
        Process.sleep(10000)
        new_connection
    end
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    {:ok, chan} = new_connection()
    {:noreply, chan}
  end
end