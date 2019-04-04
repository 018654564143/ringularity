defmodule Streams.Join do
  use GenServer

  alias Streams.Channels
  alias BlackHole.Distributor

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(init_arg) do
    monitor = fn m -> 
      cond do
        Channels.awaiting_empty? -> Process.sleep(60_000)
        true ->  process_channels()
      end
    
      m.(m)
    end

    # recursion of anomouse function
    spawn(fn -> monitor.(monitor) end)

    { :ok, init_arg}
  end

  defp process_channels do
    Channels.awaiting 
      |> Enum.each(fn channel -> join_message(channel) |> Distributor.send_to_socket end)

    # at least 15 seconds after joining 50 channels.
    Process.sleep(20000)
  end

  defp join_message(channel) do
    "JOIN ##{channel}"
  end
end