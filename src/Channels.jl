"""
Handles WebSockets communication logic.
"""
module Channels

using WebSockets

typealias ClientId  Int
typealias ChannelId String

const CLIENTS       = Dict{ClientId, Dict{Symbol, Union{WebSockets.WebSocket,Vector{ChannelId}} } }() # { ws.id => { :client => ws, :channels => ["foo", "bar", "baz"] } }
const SUBSCRIPTIONS = Dict{ChannelId,Vector{ClientId}}()  # { "foo" => ["4", "12"] }


"""
    subscribe(ws::WebSockets.WebSocket, channel::ChannelId) :: Void

Subscribes a web socket client `ws` to `channel`.
"""
function subscribe(ws::WebSockets.WebSocket, channel::ChannelId) :: Void
  if haskey(CLIENTS, ws.id)
    ! in(channel, CLIENTS[ws.id][:channels]) && push!(CLIENTS[ws.id][:channels], channel)
  else
    CLIENTS[ws.id] = Dict(
                          :client => ws,
                          :channels => ChannelId[channel]
                          )
  end

  push_subscription(ws.id, channel)

  nothing
end


"""
    unsubscribe(ws::WebSockets.WebSocket, channel::ChannelId) :: Void

Unsubscribes a web socket client `ws` from `channel`.
"""
function unsubscribe(ws::WebSockets.WebSocket, channel::ChannelId) :: Void
  if haskey(CLIENTS, ws.id)
    delete!( CLIENTS[ws.id][:channels], channel )
  end

  pop_subscription(ws.id, channel)

  nothing
end


"""
    unsubscribe_client(ws::WebSockets.WebSocket, channel::ChannelId) :: Void

Unsubscribes a web socket client `ws` from all the channels.
"""
function unsubscribe_client(ws::WebSockets.WebSocket) :: Void
  if haskey(CLIENTS, ws.id)
    delete!( CLIENTS, ws.id )
  end

  pop_subscription(ws.id)

  nothing
end


"""
    push_subscription(client::ClientId, channel::ChannelId) :: Void

Adds a new subscription for `client` to `channel`.
"""
function push_subscription(client::ClientId, channel::ChannelId) :: Void
  if haskey(SUBSCRIPTIONS, channel)
    ! in(client, SUBSCRIPTIONS[channel]) && push!(SUBSCRIPTIONS[channel], client)
  else
    SUBSCRIPTIONS[channel] = ClientId[client]
  end

  nothing
end


"""
    pop_subscription(client::ClientId, channel::ChannelId) :: Void

Removes the subscription of `client` to `channel`.
"""
function pop_subscription(client::ClientId, channel::ChannelId) :: Void
  if haskey(SUBSCRIPTIONS, channel)
    delete!(SUBSCRIPTIONS[channel], client)
  end

  nothing
end


"""
    pop_subscription(client::ClientId) :: Void

Removes all subscriptions of `client`.
"""
function pop_subscription(channel::ChannelId) :: Void
  if haskey(SUBSCRIPTIONS, channel)
    delete!(SUBSCRIPTIONS, channel)
  end

  nothing
end


"""
    broadcast(channels::Vector{ChannelId}, msg::String) :: Void

Pushes `msg` to all the clients subscribed to the channels in `channels`.
"""
function broadcast(channels::Vector{ChannelId}, msg::String) :: Void
  for channel in channels
    for client in SUBSCRIPTIONS[channel]
      write(CLIENTS[client][:client], msg)
    end
  end

  nothing
end


"""
    broadcast(msg::String) :: Void

Pushes `msg` to all the clients subscribed to all the channels.
"""
function broadcast(msg::String) :: Void
  broadcast(collect(keys(SUBSCRIPTIONS)), msg)
end

end
