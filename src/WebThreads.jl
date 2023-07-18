"""
Handles Ajax communication logic.
"""
module WebThreads

import HTTP, Distributed, Logging, Dates
import Genie, Genie.Renderer


const MESSAGE_QUEUE = Dict{UInt,Vector{String}}()

const ClientId = UInt # session id
const ChannelName = String

mutable struct ChannelClient
  client::UInt
  channels::Vector{ChannelName}
  last_active::Dates.DateTime
end

const ChannelClientsCollection = Dict{ClientId,ChannelClient} # { uint => { :client => ws, :channels => ["foo", "bar", "baz"] } }
const ChannelSubscriptionsCollection = Dict{ChannelName,Vector{ClientId}}  # { "foo" => ["4", "12"] }
const MessagePayload = Union{Nothing,Dict}

mutable struct ChannelMessage
  channel::ChannelName
  client::ClientId
  message::String
  payload::MessagePayload
end

const CLIENTS = ChannelClientsCollection()
const SUBSCRIPTIONS = ChannelSubscriptionsCollection()


clients() = collect(values(CLIENTS))
subscriptions() = SUBSCRIPTIONS
webthreads() = map(c -> c.client, clients())
channels() = collect(keys(SUBSCRIPTIONS))


function connected_clients(channel::ChannelName) :: Vector{ChannelClient}
  clients = ChannelClient[]
  for client_id in SUBSCRIPTIONS[channel]
    ((Dates.now() - CLIENTS[client_id].last_active) <= Genie.config.webthreads_connection_threshold) && push!(clients, CLIENTS[client_id])
  end

  clients
end
function connected_clients() :: Vector{ChannelClient}
  clients = ChannelClient[]
  for ch in channels()
    clients = vcat(clients, connected_clients(ch))
  end

  clients
end


function disconnected_clients(channel::ChannelName) :: Vector{ChannelClient}
  clients = ChannelClient[]
  for client_id in SUBSCRIPTIONS[channel]
    ((Dates.now() - CLIENTS[client_id].last_active) > Genie.config.webthreads_connection_threshold) && push!(clients, CLIENTS[client_id])
  end

  clients
end
function disconnected_clients() :: Vector{ChannelClient}
  clients = ChannelClient[]
  for ch in channels()
    clients = vcat(clients, disconnected_clients(ch))
  end

  clients
end


"""
Subscribes a web thread client `wt` to `channel`.
"""
function subscribe(wt::UInt, channel::ChannelName) :: ChannelClientsCollection
  if haskey(CLIENTS, wt)
    in(channel, CLIENTS[wt].channels) || push!(CLIENTS[wt].channels, channel)
  else
    CLIENTS[wt] = ChannelClient(wt, ChannelName[channel], Dates.now())
  end

  push_subscription(wt, channel)

  haskey(MESSAGE_QUEUE, wt) || (MESSAGE_QUEUE[wt] = String[])

  CLIENTS
end


"""
Unsubscribes a web socket client `wt` from `channel`.
"""
function unsubscribe(wt::UInt, channel::ChannelName) :: ChannelClientsCollection
  haskey(CLIENTS, wt) && deleteat!(CLIENTS[wt].channels, CLIENTS[wt].channels .== channel)
  pop_subscription(wt, channel)

  CLIENTS
end
function unsubscribe(channel_client::ChannelClient, channel::ChannelName) :: ChannelClientsCollection
  unsubscribe(channel_client.client, channel)
end


"""
Unsubscribes a web socket client `wt` from all the channels.
"""
function unsubscribe_client(wt::UInt) :: ChannelClientsCollection
  if haskey(CLIENTS, wt)
    for channel_id in CLIENTS[wt].channels
      pop_subscription(wt, channel_id)
    end

    delete!(CLIENTS, wt)
  end

  CLIENTS
end
function unsubscribe_client(channel_client::ChannelClient) :: ChannelClientsCollection
  unsubscribe_client(channel_client.client)

  CLIENTS
end


"""
unsubscribe_disconnected_clients() :: ChannelClientsCollection

Unsubscribes clients which are no longer connected.
"""
function unsubscribe_disconnected_clients() :: ChannelClientsCollection
  for channel_client in disconnected_clients()
    unsubscribe_client(channel_client)
  end

  CLIENTS
end
function unsubscribe_disconnected_clients(channel::ChannelName) :: ChannelClientsCollection
  for channel_client in disconnected_clients(channel)
    unsubscribe(channel_client, channel)
  end

  CLIENTS
end


function unsubscribe_clients()
  empty!(CLIENTS)
  empty!(SUBSCRIPTIONS)
end


function timestamp_client(client_id::ClientId) :: Nothing
  haskey(CLIENTS, client_id) && (CLIENTS[client_id].last_active = Dates.now())

  nothing
end


"""
Adds a new subscription for `client` to `channel`.
"""
function push_subscription(client_id::ClientId, channel::ChannelName) :: ChannelSubscriptionsCollection
  if haskey(SUBSCRIPTIONS, channel)
    ! in(client_id, SUBSCRIPTIONS[channel]) && push!(SUBSCRIPTIONS[channel], client_id)
  else
    SUBSCRIPTIONS[channel] = ClientId[client_id]
  end

  timestamp_client(client_id)

  SUBSCRIPTIONS
end
function push_subscription(channel_client::ChannelClient, channel::ChannelName) :: ChannelSubscriptionsCollection
  push_subscription(channel_client.client, channel)
end


"""
Removes the subscription of `client` to `channel`.
"""
function pop_subscription(client::ClientId, channel::ChannelName) :: ChannelSubscriptionsCollection
  if haskey(SUBSCRIPTIONS, channel)
    filter!(SUBSCRIPTIONS[channel]) do (client_id)
      client_id != client
    end
    isempty(SUBSCRIPTIONS[channel]) && delete!(SUBSCRIPTIONS, channel)
  end

  timestamp_client(client)

  SUBSCRIPTIONS
end
function pop_subscription(channel_client::ChannelClient, channel::ChannelName) :: ChannelSubscriptionsCollection
  pop_subscription(channel_client.client, channel)
end


"""
Removes all subscriptions of `client`.
"""
function pop_subscription(channel::ChannelName) :: ChannelSubscriptionsCollection
  if haskey(SUBSCRIPTIONS, channel)
    delete!(SUBSCRIPTIONS, channel)
  end

  SUBSCRIPTIONS
end


"""
Pushes `msg` (and `payload`) to all the clients subscribed to the channels in `channels`.
"""
function broadcast(channels::Union{ChannelName,Vector{ChannelName}}, msg::String;
                    except::Union{HTTP.WebSockets.WebSocket,Nothing,UInt} = nothing) :: Bool
  isa(channels, Array) || (channels = ChannelName[channels])

  for channel in channels
    if ! haskey(SUBSCRIPTIONS, channel)
      @debug(Genie.WebChannels.ChannelNotFoundException(channel))
      continue
    end

    for client in SUBSCRIPTIONS[channel]
      except !== nothing && client == except && continue

      try
        message(client, msg)
      catch ex
        @error ex
      end
    end
  end

  true
end
function broadcast(channels::Union{ChannelName,Vector{ChannelName}}, msg::String, payload::Dict) :: Bool
  isa(channels, Array) || (channels = [channels])

  for channel in channels
    if ! haskey(SUBSCRIPTIONS, channel)
      @debug(Genie.WebChannels.ChannelNotFoundException(channel))
      continue
    end

    for client in SUBSCRIPTIONS[channel]
      try
        message(client, ChannelMessage(channel, client, msg, payload) |> Renderer.Json.JSONParser.json)
      catch ex
        @error ex
      end
    end
  end

  true
end


"""
Pushes `msg` (and `payload`) to all the clients subscribed to all the channels.
"""
function broadcast(msg::String, payload::Union{Dict,Nothing} = nothing) :: Bool
  payload === nothing ?
    broadcast(collect(keys(SUBSCRIPTIONS)), msg) :
    broadcast(collect(keys(SUBSCRIPTIONS)), msg, payload)
end


"""
Pushes `msg` (and `payload`) to `channel`.
"""
function message(channel::ChannelName, msg::String, payload::Union{Dict,Nothing} = nothing) :: Bool
  payload === nothing ?
    broadcast(channel, msg) :
    broadcast(channel, msg, payload)
end


"""
Writes `msg` to message queue for `client`.
"""
function message(wt::UInt, msg::String)
  push!(MESSAGE_QUEUE[wt], msg)
end
function message(client::ChannelClient, msg::String)
  message(client.client, msg)
end


function pull(wt::UInt, channel::ChannelName)
  output = ""
  if haskey(MESSAGE_QUEUE, wt) && ! isempty(MESSAGE_QUEUE[wt])
    output = MESSAGE_QUEUE[wt] |> Renderer.Json.JSONParser.json
    empty!(MESSAGE_QUEUE[wt])
  end

  timestamp_client(wt)

  output
end

function push(params::Genie.Router.Params, wt::UInt, channel::ChannelName, message::String)
  timestamp_client(wt)

  Genie.Router.route_ws_request(params[:request], message, wt)
end

end