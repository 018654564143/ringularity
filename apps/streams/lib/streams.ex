defmodule Streams do
  def start do
    children = [
      Streams.Pusher
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
