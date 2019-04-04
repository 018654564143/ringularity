defmodule Queue.Consumer do
  use GenServer
  require Logger

  alias Streams.Channels

  @exchange  "streams_exchange"
  @queue     "streams_queue"

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_opts) do
    new_connection()
  end

  defp new_connection do
    { :ok, chan }  =  Queue.Connection.new(@queue, @exchange, true)

    Process.monitor(chan.conn.pid)
    {:ok, _consumer_tag} = AMQP.Basic.consume(chan, @queue)

    { :ok, chan }
  end

  defp consume(channel, tag, redelivered, payload) do
    payload |> String.split(",") |> Channels.add_awaits

    :ok = AMQP.Basic.ack channel, tag

  rescue
    exception ->
      :ok = AMQP.Basic.reject channel, tag, requeue: not redelivered
      IO.puts "Error converting #{payload}"
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    {:ok, chan} = new_connection()
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, chan) do
    spawn fn -> consume(chan, tag, redelivered, payload) end
    {:noreply, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end
end