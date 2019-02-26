"""
Handles WebSockets communication logic.
"""
module WebChannels

using HTTP, JSON, Distributed
using ..Loggers

const ClientId =                          UInt64
const ChannelId =                         String
const ChannelClient =                     Dict{Symbol, Union{HTTP.WebSockets.WebSocket,Vector{ChannelId}}}
const ChannelClientsCollection =          Dict{ClientId,ChannelClient} # { id(ws) => { :client => ws, :channels => ["foo", "bar", "baz"] } }
const ChannelSubscriptionsCollection =    Dict{ChannelId,Vector{ClientId}}  # { "foo" => ["4", "12"] }
const MessagePayload =                    Union{Nothing,Dict}

mutable struct ChannelMessage
  channel::ChannelId
  client::ClientId
  message::String
  payload::MessagePayload
end

const CLIENTS       = ChannelClientsCollection()
const SUBSCRIPTIONS = ChannelSubscriptionsCollection()


"""
    subscribe(ws::HTTP.WebSockets.WebSocket, channel::ChannelId) :: Nothing

Subscribes a web socket client `ws` to `channel`.
"""
function subscribe(ws::HTTP.WebSockets.WebSocket, channel::ChannelId) :: Nothing
  if haskey(CLIENTS, id(ws))
    ! in(channel, CLIENTS[id(ws)][:channels]) && push!(CLIENTS[id(ws)][:channels], channel)
  else
    CLIENTS[id(ws)] = Dict(
                          :client => ws,
                          :channels => ChannelId[channel]
                          )
  end

  push_subscription(id(ws), channel)

  nothing
end


function id(ws::HTTP.WebSockets.WebSocket)
  hash(ws)
end


"""
    unsubscribe(ws::HTTP.WebSockets.WebSocket, channel::ChannelId) :: Nothing

Unsubscribes a web socket client `ws` from `channel`.
"""
function unsubscribe(ws::HTTP.WebSockets.WebSocket, channel::ChannelId) :: Nothing
  if haskey(CLIENTS, id(ws))
    delete!(CLIENTS[id(ws)][:channels], channel)
  end

  pop_subscription(id(ws), channel)

  nothing
end


"""
    unsubscribe_client(ws::HTTP.WebSockets.WebSocket) :: Nothing

Unsubscribes a web socket client `ws` from all the channels.
"""
function unsubscribe_client(client::ClientId) :: Nothing
  unsubscribe_client(CLIENTS[client][:client])
end
function unsubscribe_client(ws::HTTP.WebSockets.WebSocket) :: Nothing
  if haskey(CLIENTS, id(ws))
    for channel_id in CLIENTS[id(ws)][:channels]
      pop_subscription(id(ws), channel_id)
    end

    delete!(CLIENTS, id(ws))
  end

  nothing
end


"""
    push_subscription(client::ClientId, channel::ChannelId) :: Nothing

Adds a new subscription for `client` to `channel`.
"""
function push_subscription(client::ClientId, channel::ChannelId) :: Nothing
  if haskey(SUBSCRIPTIONS, channel)
    ! in(client, SUBSCRIPTIONS[channel]) && push!(SUBSCRIPTIONS[channel], client)
  else
    SUBSCRIPTIONS[channel] = ClientId[client]
  end

  nothing
end


"""
    pop_subscription(client::ClientId, channel::ChannelId) :: Nothing

Removes the subscription of `client` to `channel`.
"""
function pop_subscription(client::ClientId, channel::ChannelId) :: Nothing
  if haskey(SUBSCRIPTIONS, channel)
    filter!(SUBSCRIPTIONS[channel]) do (client_id)
      client_id != client
    end
    isempty(SUBSCRIPTIONS[channel]) && delete!(SUBSCRIPTIONS, channel)
  end

  nothing
end


"""
    pop_subscription(client::ClientId) :: Nothing

Removes all subscriptions of `client`.
"""
function pop_subscription(channel::ChannelId) :: Nothing
  if haskey(SUBSCRIPTIONS, channel)
    delete!(SUBSCRIPTIONS, channel)
  end

  nothing
end


"""
    broadcast(channels::Union{ChannelId,Vector{ChannelId}}, msg::String) :: Nothing
    broadcast{U,T}(channels::Vector{ChannelId}, msg::String, payload::Dict{U,T}) :: Nothing

Pushes `msg` (and `payload`) to all the clients subscribed to the channels in `channels`.
"""
function broadcast(channels::Union{ChannelId,Vector{ChannelId}}, msg::String) :: Nothing
  isa(channels, Array) || (channels = ChannelId[channels])

  @distributed for channel in channels
    for client in SUBSCRIPTIONS[channel]
      ws_write_message(client, msg)
    end
  end

  nothing
end
function broadcast(channels::Union{ChannelId,Vector{ChannelId}}, msg::String, payload::Dict{U,T})::Nothing where {U,T}
  isa(channels, Array) || (channels = ChannelId[channels])

  @distributed for channel in channels
    in(channel, keys(SUBSCRIPTIONS)) || continue

    for client in SUBSCRIPTIONS[channel]
      try
        ws_write_message(client, ChannelMessage(channel, client, msg, payload) |> JSON.json)
      catch ex
        log(string(ex), :err)
        log("$(@__FILE__):$(@__LINE__)")

        rethrow(ex)
      end
    end
  end

  nothing
end


"""
    broadcast(msg::String) :: Nothing
    broadcast{U,T}(msg::String, payload::Dict{U,T}) :: Nothing

Pushes `msg` (and `payload`) to all the clients subscribed to all the channels.
"""
function broadcast(msg::String) :: Nothing
  broadcast(collect(keys(SUBSCRIPTIONS)), msg)
end
function broadcast(msg::String, payload::Dict{U,T})::Nothing where {U,T}
  broadcast(collect(keys(SUBSCRIPTIONS)), msg, payload)
end


"""
  message(channel::ChannelId, msg::String) :: Nothing
  message{U,T}(channel::ChannelId, msg::String, payload::Dict{U,T}) :: Nothing

Pushes `msg` (and `payload`) to `channel`.
"""
function message(channel::ChannelId, msg::String) :: Nothing
  broadcast(ChannelId[channel], msg)
end
function message(channel::ChannelId, msg::String, payload::Dict{U,T})::Nothing where {U,T}
  broadcast(ChannelId[channel], msg, payload)
end


"""
    ws_write_message(client::ClientId, msg::String) :: Nothing

Writes `msg` to web socket for `client`.
"""
function ws_write_message(client::ClientId, msg::String) :: Nothing
  write(CLIENTS[client][:client], msg)

  nothing
end


"""
    message(client::ChannelClient, msg::String) :: Nothing

Send message `msg` to `client`.
"""
function message(client::ChannelClient, msg::String) :: Nothing
  write(client[:client], msg)

  nothing
end

end
