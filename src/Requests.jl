"""
Collection of utilities for working with Requests data
"""
module Requests

import Genie, Genie.Router, Genie.Input, Genie.Context
import HTTP, Reexport
import Base: ImmutableDict
import OrderedCollections: LittleDict

export jsonpayload, rawpayload, filespayload, postpayload, getpayload
export request, getrequest, matchedroute, matchedchannel, wsclient
export infilespayload, filename, payload, peer, currenturl


"""
    jsonpayload(params::Genie.Context.Params)

Processes an `application/json` `POST` request.
If it fails to successfully parse the `JSON` data it returns `nothing`. The original payload can still be accessed invoking `rawpayload(params)`
"""
function jsonpayload(params::Genie.Context.Params)
  params.collection[:json]
end


"""
    rawpayload(params::Genie.Context.Params) :: String

Returns the raw `POST` payload as a `String`.
"""
function rawpayload(params::Genie.Context.Params) :: String
  params.collection[:raw]
end


"""
    filespayload(params::Genie.Context.Params)

Collection of form uploaded files.
"""
function filespayload(params::Genie.Context.Params)
  params.collection[:files]
end


"""
    Base.write(filename::String = file.name; file::Input.HttpFile) :: IntBase.write(file::HttpFile, filename::String = file.name)

Writes uploaded `HttpFile` `file` to local storage under the `name` filename.
Returns number of bytes written.
"""
function Base.write(file::Input.HttpFile; filename::String = file.name) :: Int
  write(filename, IOBuffer(file.data))
end


"""
    read(file::HttpFile)

Returns the content of `file` as string.
"""
function Base.read(file::Input.HttpFile, ::Type{String}) :: String
  file.data |> String
end


"""
    filename(file::HttpFile) :: String

Original filename of the uploaded `HttpFile` `file`.
"""
function filename(file::Input.HttpFile) :: String
  file.name
end


"""
    postpayload(params::Genie.Context.Params) :: Dict{Symbol,Any}

A dict representing the POST variables payload of the request (corresponding to a `form-data` request)
"""
function postpayload(params::Genie.Context.Params)
  params.collection[:post]
end


"""
    getpayload(params::Genie.Context.Params)

A dict representing the GET/query variables payload of the request (the part corresponding to `?foo=bar&baz=moo`)
"""
function getpayload(params::Genie.Context.Params)
  params.collection[:query]
end


"""
    request(params::Genie.Context.Params) :: HTTP.Request

Returns the raw HTTP.Request object associated with the request. If no request is available (not within a
request/response cycle) returns `nothing`.
"""
function request(params::Genie.Context.Params) :: Union{HTTP.Request,Nothing}
  params.collection[:request]
end


"""
    matchedroute(params::Genie.Context.Params) :: Union{Genie.Router.Route,Nothing}

Returns the `Route` object which was matched for the current request or `noting` if no route is available.
"""
function matchedroute(params::Genie.Context.Params) :: Union{Genie.Router.Route,Nothing}
  params.collection[:route]
end


"""
    matchedchannel(params::Genie.Context.Params) :: Union{Genie.Router.Channel,Nothing}

Returns the `Channel` object which was matched for the current request or `nothing` if no channel is available.
"""
function matchedchannel(params::Genie.Context.Params) :: Union{Genie.Router.Channel,Nothing}
  params.collection[:channel]
end


"""
    wsclient(params::Genie.Context.Params) :: Union{HTTP.WebSockets.WebSocket,Nothing}

The web sockets client for the current request or nothing if not available.
"""
function wsclient(params::Genie.Context.Params) :: Union{HTTP.WebSockets.WebSocket,Nothing}
  params.collection[:wsclient]
end


"""
    wtclient(params::Genie.Context.Params) :: UInt

The web sockets client for the current request.
"""
function wtclient(params::Genie.Context.Params) :: UInt
  params.collection[:wtclient] |> hash
end


function getheaders(req::HTTP.Request) :: ImmutableDict{<:AbstractString,<:AbstractString}
  ImmutableDict{String,String}(req.headers)
end


"""
    findheader(params::Genie.Context.Params, key::String, default::Any = nothing) :: Union{String,Nothing}

Case insensitive search for the header `key` in the request headers. If `key` is not found, `default` is returned.
"""
function findheader(params::Genie.Context.Params, key::T, default = nothing)::Union{T,Nothing} where T<:AbstractString
  for (k, v) in getheaders(params[:request])
    if lowercase(k) === lowercase(key)
      return v
    end
  end

  default
end


"""
    peer()

Returns information about the requesting client's IP address as a NamedTuple{(:ip,), Tuple{String}}
If the client IP address can not be retrieved, the `ip` field will return an empty string `""`.
"""
function peer()
  unset_peer = (ip = "", port = "")

  if haskey(task_local_storage(), :peer)
    try
      (ip = string(task_local_storage(:peer)[1]), port = string(task_local_storage(:peer)[2]))
    catch ex
      @error ex
      unset_peer
    end
  else
    unset_peer
  end
end


"""
    isajax(req::HTTP.Request = getrequest()) :: Bool

Attempts to determine if a request is Ajax by sniffing the headers.
"""
function isajax(req::HTTP.Request) :: Bool
  for (k,v) in getheaders(req)
    k = replace(k, r"_|-"=>"") |> lowercase
    occursin("requestedwith", k) && occursin("xmlhttp", lowercase(v)) && return true
  end

  return false
end


"""
    currenturl() :: String

Returns the URL of the current page/request, starting from the path and including the query string.

### Example

```julia
currenturl()
"/products?promotions=yes"
```
"""
function currenturl(req::HTTP.Request) :: String
  req.target
end

end
