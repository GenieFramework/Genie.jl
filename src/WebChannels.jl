"""
Handles WebSockets communication logic.
"""
module WebChannels

import HTTP, Distributed, Logging, JSON3, Sockets, Dates, Base64
import Genie, Genie.Renderer

const ClientId = UInt # web socket hash
const ChannelName = String
const MESSAGE_QUEUE = Dict{UInt, Tuple{
  Channel{Tuple{String, Channel{Int}}},
  Task}
}()

struct ChannelNotFoundException <: Exception
  name::ChannelName
end

mutable struct ChannelClient
  client::HTTP.WebSockets.WebSocket
  channels::Vector{ChannelName}
end

const ChannelClientsCollection = Dict{ClientId,ChannelClient} # { id(ws) => { :client => ws, :channels => ["foo", "bar", "baz"] } }
const ChannelSubscriptionsCollection = Dict{ChannelName,Vector{ClientId}}  # { "foo" => ["4", "12"] }
const MessagePayload = Union{Nothing,Dict}

mutable struct ChannelMessage
  channel::ChannelName
  client::ClientId
  message::String
  payload::MessagePayload
end

function JSON3.StructTypes.StructType(::Type{T}) where {T<:ChannelMessage}
  JSON3.StructTypes.Struct()
end

const CLIENTS = ChannelClientsCollection()
const SUBSCRIPTIONS = ChannelSubscriptionsCollection()


clients() = collect(values(CLIENTS))
subscriptions() = SUBSCRIPTIONS
websockets() = map(c -> c.client, clients())
channels() = collect(keys(SUBSCRIPTIONS))


function connected_clients(channel::ChannelName) :: Vector{ChannelClient}
  clients = ChannelClient[]
  for client_id in SUBSCRIPTIONS[channel]
    ! HTTP.WebSockets.isclosed(CLIENTS[client_id].client) && push!(clients, CLIENTS[client_id])
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
    HTTP.WebSockets.isclosed(CLIENTS[client_id].client) && push!(clients, CLIENTS[client_id])
  end

  clients
end
function disconnected_clients() :: Vector{ChannelClient}
  channel_clients = ChannelClient[]
  for channel_client in clients()
    HTTP.WebSockets.isclosed(channel_client.client) && push!(channel_clients, channel_client)
  end

  channel_clients
end


"""
Subscribes a web socket client `ws` to `channel`.
"""
function subscribe(ws::HTTP.WebSockets.WebSocket, channel::ChannelName) :: ChannelClientsCollection
  if haskey(CLIENTS, id(ws))
    in(channel, CLIENTS[id(ws)].channels) || push!(CLIENTS[id(ws)].channels, channel)
  else
    CLIENTS[id(ws)] = ChannelClient(ws, ChannelName[channel])
  end

  push_subscription(id(ws), channel)

  @debug "Subscribed: $(id(ws)) ($(Dates.now()))"
  CLIENTS
end


function id(ws::HTTP.WebSockets.WebSocket) :: UInt
  hash(ws)
end


"""
Unsubscribes a web socket client `ws` from `channel`.
"""
function unsubscribe(ws::HTTP.WebSockets.WebSocket, channel::ChannelName) :: ChannelClientsCollection
  client = id(ws)

  haskey(CLIENTS, client) && deleteat!(CLIENTS[client].channels, CLIENTS[client].channels .== channel)
  pop_subscription(client, channel)
  delete_queue!(MESSAGE_QUEUE, client)

  @debug "Unsubscribed: $(client) ($(Dates.now()))"
  CLIENTS
end
function unsubscribe(channel_client::ChannelClient, channel::ChannelName) :: ChannelClientsCollection
  unsubscribe(channel_client.client, channel)
end


"""
Unsubscribes a web socket client `ws` from all the channels.
"""
function unsubscribe_client(ws::HTTP.WebSockets.WebSocket) :: ChannelClientsCollection
  if haskey(CLIENTS, id(ws))
    for channel_id in CLIENTS[id(ws)].channels
      pop_subscription(id(ws), channel_id)
    end

    delete!(CLIENTS, id(ws))
  end

  CLIENTS
end
function unsubscribe_client(client_id::ClientId) :: ChannelClientsCollection
  unsubscribe_client(CLIENTS[client_id].client)

  CLIENTS
end
function unsubscribe_client(channel_client::ChannelClient) :: ChannelClientsCollection
  unsubscribe_client(channel_client.client)

  CLIENTS
end


function purge_unnecessary_message_queue()
  active_clients = keys(CLIENTS) |> collect
  for id in keys(MESSAGE_QUEUE) |> collect
    if ! (id in active_clients)
      delete!(MESSAGE_QUEUE, id)
    end
  end
end


"""
unsubscribe_disconnected_clients() :: ChannelClientsCollection

Unsubscribes clients which are no longer connected.
"""
function unsubscribe_disconnected_clients() :: ChannelClientsCollection
  for channel_client in disconnected_clients()
    unsubscribe_client(channel_client)
  end

  @async purge_unnecessary_message_queue() |> errormonitor

  CLIENTS
end
function unsubscribe_disconnected_clients(channel::ChannelName) :: ChannelClientsCollection
  for channel_client in disconnected_clients(channel)
    unsubscribe(channel_client, channel)
  end

  CLIENTS
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

  SUBSCRIPTIONS
end
function push_subscription(channel_client::ChannelClient, channel::ChannelName) :: ChannelSubscriptionsCollection
  push_subscription(id(channel_client.client), channel)
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

  SUBSCRIPTIONS
end
function pop_subscription(channel_client::ChannelClient, channel::ChannelName) :: ChannelSubscriptionsCollection
  pop_subscription(id(channel_client.client), channel)
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
Pushes `msg` (and `payload`) to all the clients subscribed to the channels in `channels`, with the exception of `except`.
"""
function broadcast(channels::Union{ChannelName,Vector{ChannelName}},
                    msg::String,
                    payload::Union{Dict,Nothing} = nothing;
                    except::Union{Nothing,UInt,Vector{UInt}} = nothing,
                    restrict::Union{Nothing,UInt,Vector{UInt}} = nothing) :: Bool
  isa(channels, Array) || (channels = ChannelName[channels])

  isempty(SUBSCRIPTIONS) && return false

  @async unsubscribe_disconnected_clients() |> errormonitor

  # @show channels
  # @show CLIENTS

  # try
  for channel in channels
    if ! haskey(SUBSCRIPTIONS, channel)
      unsubscribe_disconnected_clients(channel)
      throw(ChannelNotFoundException(channel))
    end

    ids = restrict === nothing ? SUBSCRIPTIONS[channel] : intersect(SUBSCRIPTIONS[channel], restrict)
    for client in ids
      if except !== nothing
        except isa UInt && client == except && continue
        except isa Vector{UInt} && client ∈ except && continue
      end
      HTTP.WebSockets.isclosed(CLIENTS[client].client) && continue

      try
        payload !== nothing ?
          message(client, ChannelMessage(channel, client, msg, payload) |> Renderer.Json.JSONParser.json) :
          message(client, msg)
      catch ex
        if isa(ex, Base.IOError)
          unsubscribe_disconnected_clients(channel)
        else
          @error ex
        end
      end
    end
  end
  # catch ex
  #   @warn ex
  # end

  true
end


"""
Pushes `msg` (and `payload`) to all the clients subscribed to the channels in `channels`, with the exception of `except`.
"""
function broadcast(msg::String;
                    channels::Union{Union{ChannelName,Vector{ChannelName}},Nothing} = nothing,
                    payload::Union{Dict,Nothing} = nothing,
                    except::Union{HTTP.WebSockets.WebSocket,Nothing,UInt} = nothing) :: Bool
  try
    channels === nothing && (channels = collect(keys(SUBSCRIPTIONS)))
    broadcast(channels, msg, payload; except = except)
  catch ex
    @error ex
    false
  end
end


"""
Pushes `js_code` (a JavaScript piece of code) to be executed by all the clients subscribed to the channels in `channels`,
with the exception of `except`.
"""
function jscomm(js_code::String, channels::Union{Union{ChannelName,Vector{ChannelName}},Nothing} = nothing;
            except::Union{HTTP.WebSockets.WebSocket,Nothing,UInt} = nothing)
  broadcast(string(Genie.config.webchannels_eval_command, js_code); channels = channels, except = except)
end


"""
Writes `msg` to web socket for `client`.
"""
function message(client::ClientId, msg::String)
  ws = Genie.WebChannels.CLIENTS[client].client
  # setup a reply channel
  myfuture = Channel{Int}(1)

  # retrieve the message queue or set it up if not present
  q, _ = get!(MESSAGE_QUEUE, client) do
    queue = Channel{Tuple{String, Channel{Int}}}(10)
    handler = @async while true
      message, future = take!(queue)
      nbytes = 0
      try
        nbytes = Sockets.send(ws, message)
      catch
        @debug "Sending message to $(repr(client)) failed!"
      finally
        put!(future, nbytes)
      end
    end |> errormonitor

    queue, handler
  end

  put!(q, (msg, myfuture))

  take!(myfuture) # Wait until the message is processed
end
function message(client::ChannelClient, msg::String) :: Int
  message(client.client, msg)
end
function message(ws::HTTP.WebSockets.WebSocket, msg::String) :: Int
  message(id(ws), msg)
end

function message_unsafe(ws::HTTP.WebSockets.WebSocket, msg::String) :: Int
  Sockets.send(ws, msg)
end
function message_unsafe(client::ClientId, msg::String) :: Int
  message_unsafe(CLIENTS[client].client, msg)
end
function message_unsafe(client::ChannelClient, msg::String) :: Int
  message_unsafe(client.client, msg)
end

function delete_queue!(d::Dict, client::UInt)
  queue, handler = pop!(MESSAGE_QUEUE, client, (nothing, nothing))
  if queue !== nothing
    @async Base.throwto(handler, InterruptException()) |> errormonitor
  end
end

"""
Encodes `msg` in Base64 and tags it with `Genie.config.webchannels_base64_marker`.
"""
function tagbase64encode(msg)
  Genie.config.webchannels_base64_marker * Base64.base64encode(msg)
end


"""
Decodes `msg` from Base64 and removes the `Genie.config.webchannels_base64_marker` tag.
"""
function tagbase64decode(msg)
  Base64.base64decode(msg[length(Genie.config.webchannels_base64_marker):end])
end

end
