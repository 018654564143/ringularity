defmodule Twitch.Streamers do
  def list do
    all_streams([], %{})
  end

  defp all_streams(streams, opts) when streams == [] and opts == %{} do
    api_info = Application.get_env(:streams, :twitch)
    opts = options(api_info)

    page_content = fetch_streams(opts)
    new_streams  = page_content.streams

    opts = Map.merge(opts, %{cursor: page_content, url: "#{opts.url}&after=#{page_content.cursor}"})

    all_streams(streams ++ new_streams, opts, Enum.count(new_streams))
  end

  defp all_streams(streams, opts, streams_count) when streams_count == 100 do
    IO.puts(Enum.count(streams))
    Process.sleep(200)

    page_content = fetch_streams(opts)
    new_streams  = page_content.streams

    opts = Map.merge(opts, %{cursor: page_content.cursor, url: "#{opts.base_url}&after=#{page_content.cursor}"})
    all_streams(streams ++ new_streams, opts, Enum.count(new_streams))
  end

  defp all_streams(streams, _opts, streams_counter) when streams_counter < 100, do: streams |> Enum.uniq |> Enum.join(",")
  
  defp fetch_streams(opts) do
    case Request.Simple.get(opts.url, opts.headers) do
      { :error, error } -> raise error
      { :ok, response } -> response |> clean_response
    end
  end

  defp clean_response(response) do
    res = Jason.decode!(response.body, %{})
    streamers_list = res["data"] |> Enum.map(fn stream -> stream["user_name"] end)
    %{ cursor: res["pagination"]["cursor"], streams: streamers_list }
  end

  defp options(api) do
    %{
      headers:  [ { "Authorization", "Bearer #{api.auth_token}" } ],
      url:      "#{api.url}/streams?first=100",
      base_url: "#{api.url}/streams?first=100"
    }
  end 
end