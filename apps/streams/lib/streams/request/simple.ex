defmodule Request.Simple do

  def get(url, headers\\ []) do
    case HTTPoison.get(url, headers) do
      {:ok, response }            -> { :ok, response }
      {:error, %{reason: reason}} -> { :error, reason }
    end
  end

  def post(url, headers\\ []) do
    case HTTPoison.post(url, headers) do
      {:ok, response}             -> { :ok,   response }
      {:error, %{reason: reason}} -> { :error, reason }
    end
  end
end