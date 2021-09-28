"""
Collection of utilities for working with Requests data
"""
module Requests
using DocStringExtensionsMock

import Genie, Genie.Router, Genie.Input
import HTTP, Reexport

export jsonpayload, rawpayload, filespayload, postpayload, getpayload
export request, getrequest, matchedroute, matchedchannel, wsclient
export infilespayload, filename, payload, peer


"""
$TYPEDSIGNATURES

Processes an `application/json` `POST` request.
If it fails to successfully parse the `JSON` data it returns `nothing`. The original payload can still be accessed invoking `rawpayload()`
"""
function jsonpayload()
  Router.params(Genie.PARAMS_JSON_PAYLOAD)
end


"""
$TYPEDSIGNATURES

Processes an `application/json` `POST` request attempting to return value corresponding to key v.
"""
function jsonpayload(v)
  jsonpayload()[v]
end


"""
$TYPEDSIGNATURES

Returns the raw `POST` payload as a `String`.
"""
function rawpayload() :: String
  Router.params(Genie.PARAMS_RAW_PAYLOAD)
end


"""
$TYPEDSIGNATURES

Collection of form uploaded files.
"""
function filespayload() :: Dict{String,Input.HttpFile}
  Router.params(Genie.PARAMS_FILES)
end


"""
$TYPEDSIGNATURES

Returns the `HttpFile` uploaded through the `key` input name.
"""
function filespayload(key::Union{String,Symbol}) :: Input.HttpFile
  Router.params(Genie.PARAMS_FILES)[string(key)]
end


"""
$TYPEDSIGNATURES

Checks if the collection of uploaded files contains a file stored under the `key` name.
"""
function infilespayload(key::Union{String,Symbol}) :: Bool
  haskey(filespayload(), string(key))
end


"""
$TYPEDSIGNATURES

Writes uploaded `HttpFile` `file` to local storage under the `name` filename.
Returns number of bytes written.
"""
function Base.write(file::Input.HttpFile; filename::String = file.name) :: Int
  write(filename, IOBuffer(file.data))
end


"""
$TYPEDSIGNATURES

Returns the content of `file` as string.
"""
function Base.read(file::Input.HttpFile, ::Type{String}) :: String
  file.data |> String
end


"""
$TYPEDSIGNATURES

Original filename of the uploaded `HttpFile` `file`.
"""
function filename(file::Input.HttpFile) :: String
  file.name
end


"""
$TYPEDSIGNATURES

A dict representing the POST variables payload of the request (corresponding to a `form-data` request)
"""
function postpayload() :: Dict{Symbol,Any}
  Router.params(Genie.PARAMS_POST_KEY)
end


"""
$TYPEDSIGNATURES

Returns the value of the POST variables `key`.
"""
function postpayload(key::Symbol)
  postpayload()[key]
end


"""
$TYPEDSIGNATURES

Returns the value of the POST variables `key` or the `default` value if `key` is not defined.
"""
function postpayload(key::Symbol, default::Any)
  haskey(postpayload(), key) ? postpayload(key) : default
end


"""
$TYPEDSIGNATURES

A dict representing the GET/query variables payload of the request (the part correspoding to `?foo=bar&baz=moo`)
"""
function getpayload() :: Dict{Symbol,Any}
  Router.params(Genie.PARAMS_GET_KEY)
end


"""
$TYPEDSIGNATURES

The value of the GET/query variable `key`, as in `?key=value`
"""
function getpayload(key::Symbol) :: Any
  getpayload()[key]
end


"""
$TYPEDSIGNATURES

The value of the GET/query variable `key`, as in `?key=value`. If `key` is not defined, `default` is returned.
"""
function getpayload(key::Symbol, default::Any) :: Any
  haskey(getpayload(), key) ? getpayload(key) : default
end


"""
$TYPEDSIGNATURES

Returns the raw HTTP.Request object associated with the request.
"""
function request() :: HTTP.Request
  Router.params(Genie.PARAMS_REQUEST_KEY)
end

const getrequest = request

"""
$TYPEDSIGNATURES

Utility function for accessing the `params` collection, which holds the request variables.
"""
function payload() :: Dict
  Router.params()
end


"""
$TYPEDSIGNATURES

Utility function for accessing the `key` value within the `params` collection of request variables.
"""
function payload(key::Symbol) :: Any
  Router.params()[key]
end


"""
$TYPEDSIGNATURES

Utility function for accessing the `key` value within the `params` collection of request variables.
If `key` is not defined, `default_value` is returned.
"""
function payload(key::Symbol, default_value::T)::T where {T}
  haskey(Router.params(), key) ? Router.params()[key] : default_value
end


"""
$TYPEDSIGNATURES

Returns the `Route` object which was matched for the current request.
"""
function matchedroute() :: Genie.Router.Route
  Router.params(Genie.PARAMS_ROUTE_KEY)
end


"""
$TYPEDSIGNATURES

Returns the `Channel` object which was matched for the current request.
"""
function matchedchannel() :: Genie.Router.Channel
  Router.params(Genie.PARAMS_CHANNELS_KEY)
end


"""
$TYPEDSIGNATURES

The web sockets client for the current request.
"""
function wsclient() :: HTTP.WebSockets.WebSocket
  Router.params(Genie.PARAMS_WS_CLIENT)
end


"""
$TYPEDSIGNATURES

The web sockets client for the current request.
"""
function wtclient() :: UInt
  Router.params(:wtclient) |> hash
end


"""
$TYPEDSIGNATURES
"""
function getheaders(req::HTTP.Request) :: Dict{String,String}
  Dict{String,String}(req.headers)
end
"""
$TYPEDSIGNATURES
"""
function getheaders() :: Dict{String,String}
  getheaders(getrequest())
end


"""
$TYPEDSIGNATURES

Returns information about the requesting client's IP address as a NamedTuple{(:ip,), Tuple{String}}
If the client IP address can not be retrieved, the `ip` field will return an empty string `""`.
"""
function peer() :: NamedTuple{(:ip,:port), Tuple{String,String}}
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
$TYPEDSIGNATURES

Attempts to determine if a request is Ajax by sniffing the headers.
"""
function isajax(req::HTTP.Request = getrequest()) :: Bool
  for (k,v) in getheaders(req)
    k = replace(k, r"_|-"=>"") |> lowercase
    occursin("requestedwith", k) && occursin("xmlhttp", lowercase(v)) && return true
  end

  return false
end

end