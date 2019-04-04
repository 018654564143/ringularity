defmodule Streams.Channels do
  use Agent

  def start_link(_initial_value) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def awaiting do
    Agent.get(__MODULE__, & &1)
  end

  def add_single_await(channel) do
    Agent.update(__MODULE__, &(&1 ++ [channel]))
  end


  @spec add_awaits(any()) :: :ok
  def add_awaits(channels) do
    Agent.update(__MODULE__, &(&1 ++ channels))
  end

  def remove_await(channel) do
    Agent.update(__MODULE__, &(&1 -- [channel]))
  end
  def awaiting_empty? do
    awaiting() === []
  end

  def pick_await do
    { awaiting_channels, _ }  = awaiting() |> Enum.split(49)

    awaiting_channels
  end

  def count_awaits do
   awaiting() |> Enum.count
  end
end