defmodule Queue.Connection do
  use AMQP

  def new(queue, exchange, fanout\\ false) do
    case Connection.open("amqp://guest:guest@localhost") do
      {:ok, conn} ->
        {:ok, chan} = Channel.open(conn)
        setup_queue(chan, queue, exchange, fanout)

        Basic.qos(chan, prefetch_count: 10)
        {:ok, chan}
  
      {:error, _} ->
        Process.sleep(10000)
        new(queue, exchange, fanout)
    end
  end

  defp setup_queue(chan, queue, exchange, fanout) do
    Queue.declare chan, queue

    if fanout do
      Exchange.fanout chan, exchange, durable: true
    else
      Exchange.declare chan, exchange
    end

    Queue.bind chan, queue, exchange
  end
end