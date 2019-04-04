defmodule BlackHole do
  def start do
    children = [
      BlackHole.Distributor,
      Streams.Channels,
      Streams.Join,
      Queue.Supervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
