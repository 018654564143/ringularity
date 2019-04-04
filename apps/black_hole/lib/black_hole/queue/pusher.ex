defmodule Queue.Pusher do
  use GenServer

  @exchange  "mesasges_exchange"
  @queue     "mesasges_queue"

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
    { :ok, chan }  =  Queue.Connection.new(@queue, @exchange)

    Process.monitor(chan.conn.pid)

    { :ok, chan }
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    {:ok, chan} = new_connection()
    {:noreply, chan}
  end
end