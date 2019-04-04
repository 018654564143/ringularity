defmodule BlackHole.Websocket do
  alias Streams.Channels

  require Logger

  @pong "PONG :tmi.twitch.tv"

  def connect do
    socket = Socket.Web.connect! "irc-ws.chat.twitch.tv", secure: true

    cmds = ["PASS oauth:nu2wc44ze13dxj46sjf9z8ualss1cy", "NICK staterbot", "JOIN #gretaandromica"]

    :ok = Enum.each(cmds, fn cmd -> push(socket, cmd) end)

    socket
  end


  def push(socket, msg) do
    socket 
      |> Socket.Web.send!({ :text, msg })
  end

  def pull(socket) do
    { :text, data } = socket |> Socket.Web.recv!

    cond do
      data =~ "PING :tmi.twitch.tv" ->
        push(socket, @pong)

        Logger.info "Pong requested",  ansi_color: :yellow

        { :skip, "ping" }
      true ->
        pass_through(data)
    end
  end

  defp pass_through(data) do
    [ notice | _ ] = data |> String.split(" :")
    channel_info = Regex.run(~r{#\S+}, notice)

    cond do
      notice =~ "PART #" -> 
        Logger.warn "Part from channel #{channel_info}", ansi_color: :red

        { :skip, data }
      notice =~ "JOIN #" ->
        get_name(channel_info)
          |> String.replace("#", "") 
          |> Channels.remove_await

        Logger.info "Joined channel #{channel_info}",  ansi_color: :yellow

        { :skip, data }
      
      true -> { :pass, data }
    end
  end

  defp get_name(nil), do: ""

  defp get_name(name), do: hd(name) 
end