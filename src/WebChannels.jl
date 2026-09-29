"""
Handles WebSockets communication logic.
"""
module WebChannels

import HTTP, Distributed, Logging, Sockets, Dates, Base64
import Genie, Genie.Renderer, Genie.Util.killtask

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

const CLIENTS = ChannelClientsCollection()
const SUBSCRIPTIONS = ChannelSubscriptionsCollection()

"""
Guards `CLIENTS`, `SUBSCRIPTIONS`, and `MESSAGE_QUEUE`. All three are mutated
together by subscribe/unsubscribe, and under `server_ws_handler_mode = :threads`
concurrent WebSocket connections can dispatch handler code (and therefore these
mutations) onto different threads at once — a plain `Dict` is not safe for that.
One lock is used for all three (rather than per-collection) because they're
always touched as a unit here, which avoids any lock-ordering concern.
"""
const WEBCHANNELS_LOCK = ReentrantLock()


clients() = lock(WEBCHANNELS_LOCK) do
  collect(values(CLIENTS))
end
subscriptions() = lock(WEBCHANNELS_LOCK) do
  Dict(k => copy(v) for (k, v) in SUBSCRIPTIONS)
end
websockets() = map(c -> c.client, clients())
channels() = lock(WEBCHANNELS_LOCK) do
  collect(keys(SUBSCRIPTIONS))
end


function connected_clients(channel::ChannelName) :: Vector{ChannelClient}
  candidates = lock(WEBCHANNELS_LOCK) do
    [CLIENTS[client_id] for client_id in SUBSCRIPTIONS[channel]]
  end

  clients = ChannelClient[]
  for channel_client in candidates
    ! HTTP.WebSockets.isclosed(channel_client.client) && push!(clients, channel_client)
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
  candidates = lock(WEBCHANNELS_LOCK) do
    [CLIENTS[client_id] for client_id in SUBSCRIPTIONS[channel]]
  end

  clients = ChannelClient[]
  for channel_client in candidates
    HTTP.WebSockets.isclosed(channel_client.client) && push!(clients, channel_client)
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
  lock(WEBCHANNELS_LOCK) do
    if haskey(CLIENTS, id(ws))
      in(channel, CLIENTS[id(ws)].channels) || push!(CLIENTS[id(ws)].channels, channel)
    else
      CLIENTS[id(ws)] = ChannelClient(ws, ChannelName[channel])
    end

    push_subscription(id(ws), channel)

    # Clean up stale entries from previous connections on this channel so that
    # disconnected clients (and their handler tasks) do not accumulate on reconnect.
    unsubscribe_disconnected_clients(channel)

    @debug "Subscribed: $(id(ws)) ($(Dates.now()))"
    CLIENTS
  end
end


function id(ws::HTTP.WebSockets.WebSocket) :: UInt
  hash(ws)
end


"""
Unsubscribes a web socket client `ws` from `channel`.
"""
function unsubscribe(ws::HTTP.WebSockets.WebSocket, channel::ChannelName) :: ChannelClientsCollection
  lock(WEBCHANNELS_LOCK) do
    client = id(ws)

    haskey(CLIENTS, client) && deleteat!(CLIENTS[client].channels, CLIENTS[client].channels .== channel)
    pop_subscription(client, channel)
    delete_queue!(MESSAGE_QUEUE, client)

    @debug "Unsubscribed: $(client) ($(Dates.now()))"
    CLIENTS
  end
end
function unsubscribe(channel_client::ChannelClient, channel::ChannelName) :: ChannelClientsCollection
  unsubscribe(channel_client.client, channel)
end


"""
Unsubscribes a web socket client `ws` from all the channels.
"""
function unsubscribe_client(ws::HTTP.WebSockets.WebSocket) :: ChannelClientsCollection
  lock(WEBCHANNELS_LOCK) do
    client_id = id(ws)
    if haskey(CLIENTS, client_id)
      for channel_id in CLIENTS[client_id].channels
        pop_subscription(client_id, channel_id)
      end

      delete_queue!(MESSAGE_QUEUE, client_id)
      delete!(CLIENTS, client_id)
    end

    CLIENTS
  end
end
function unsubscribe_client(client_id::ClientId) :: ChannelClientsCollection
  ws = lock(WEBCHANNELS_LOCK) do
    CLIENTS[client_id].client
  end
  unsubscribe_client(ws)

  CLIENTS
end
function unsubscribe_client(channel_client::ChannelClient) :: ChannelClientsCollection
  unsubscribe_client(channel_client.client)

  CLIENTS
end


function purge_unnecessary_message_queue()
  lock(WEBCHANNELS_LOCK) do
    active_clients = keys(CLIENTS) |> collect
    for id in keys(MESSAGE_QUEUE) |> collect
      if ! (id in active_clients)
        delete_queue!(MESSAGE_QUEUE, id)  # kills the handler task, not just the dict entry
      end
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

  @async(purge_unnecessary_message_queue()) |> errormonitor

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
  lock(WEBCHANNELS_LOCK) do
    if haskey(SUBSCRIPTIONS, channel)
      ! in(client_id, SUBSCRIPTIONS[channel]) && push!(SUBSCRIPTIONS[channel], client_id)
    else
      SUBSCRIPTIONS[channel] = ClientId[client_id]
    end

    SUBSCRIPTIONS
  end
end
function push_subscription(channel_client::ChannelClient, channel::ChannelName) :: ChannelSubscriptionsCollection
  push_subscription(id(channel_client.client), channel)
end


"""
Removes the subscription of `client` to `channel`.
"""
function pop_subscription(client::ClientId, channel::ChannelName) :: ChannelSubscriptionsCollection
  lock(WEBCHANNELS_LOCK) do
    if haskey(SUBSCRIPTIONS, channel)
      filter!(SUBSCRIPTIONS[channel]) do (client_id)
        client_id != client
      end
      isempty(SUBSCRIPTIONS[channel]) && delete!(SUBSCRIPTIONS, channel)
    end

    SUBSCRIPTIONS
  end
end
function pop_subscription(channel_client::ChannelClient, channel::ChannelName) :: ChannelSubscriptionsCollection
  pop_subscription(id(channel_client.client), channel)
end


"""
Removes all subscriptions of `client`.
"""
function pop_subscription(channel::ChannelName) :: ChannelSubscriptionsCollection
  lock(WEBCHANNELS_LOCK) do
    if haskey(SUBSCRIPTIONS, channel)
      delete!(SUBSCRIPTIONS, channel)
    end

    SUBSCRIPTIONS
  end
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

  lock(WEBCHANNELS_LOCK) do
    isempty(SUBSCRIPTIONS)
  end && return false

  @async(unsubscribe_disconnected_clients()) |> errormonitor

  for channel in channels
    # Snapshot the subscriber ids and their current client objects under the
    # lock, and iterate the snapshot below — not the live SUBSCRIPTIONS[channel]
    # vector, which the `unsubscribe_disconnected_clients` task above can
    # mutate in place (via `filter!`) while this loop is still running.
    ids, client_lookup = lock(WEBCHANNELS_LOCK) do
      haskey(SUBSCRIPTIONS, channel) || return (nothing, nothing)
      ids_ = restrict === nothing ? copy(SUBSCRIPTIONS[channel]) : intersect(SUBSCRIPTIONS[channel], restrict)
      (ids_, Dict(cid => CLIENTS[cid] for cid in ids_ if haskey(CLIENTS, cid)))
    end

    if ids === nothing
      unsubscribe_disconnected_clients(channel)
      throw(ChannelNotFoundException(channel))
    end

    for client in ids
      if except !== nothing
        except isa UInt && client == except && continue
        except isa Vector{UInt} && client ∈ except && continue
      end
      haskey(client_lookup, client) || continue
      HTTP.WebSockets.isclosed(client_lookup[client].client) && continue

      try
        payload !== nothing ?
          message(client, ChannelMessage(channel, client, msg, payload) |> Genie.JSONParser.json) :
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
    channels === nothing && (channels = lock(WEBCHANNELS_LOCK) do
      collect(keys(SUBSCRIPTIONS))
    end)
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
  # setup a reply channel
  myfuture = Channel{Int}(1)

  # retrieve the message queue or set it up if not present. Only the dict
  # touch itself is locked — the queue's handler task (started below) does
  # the actual blocking network send, which must not happen while holding
  # WEBCHANNELS_LOCK.
  q, _ = lock(WEBCHANNELS_LOCK) do
    ws = CLIENTS[client].client

    get!(MESSAGE_QUEUE, client) do
      queue = Channel{Tuple{String, Channel{Int}}}(10)
      handler = @async(for (message, future) in queue
        nbytes = 0
        try
          nbytes = HTTP.WebSockets.send(ws, message)
        catch
          @debug "Sending message to $(repr(client)) failed!"
        finally
          put!(future, nbytes)
        end
        # Self-terminate when the socket is closed to avoid orphaned tasks.
        if HTTP.WebSockets.isclosed(ws)
          @info "closing ws"
          break
        end
      end) |> errormonitor

      queue, handler
    end
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
  HTTP.WebSockets.send(ws, msg)
end
function message_unsafe(client::ClientId, msg::String) :: Int
  ws = lock(WEBCHANNELS_LOCK) do
    CLIENTS[client].client
  end
  message_unsafe(ws, msg)
end
function message_unsafe(client::ChannelClient, msg::String) :: Int
  message_unsafe(client.client, msg)
end

function delete_queue!(d::Dict, client::UInt)
  queue, handler = lock(WEBCHANNELS_LOCK) do
    pop!(MESSAGE_QUEUE, client, (nothing, nothing))
  end
  if queue !== nothing
    close(queue)
    # close(queue) will normally cause the handler task to exit, but we add a killtask to be sure.
    @async(killtask(handler, wait_for_started_duration = 0.1) |> errormonitor)
  end
  return d
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
