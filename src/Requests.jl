"""
Collection of utilities for working with Requests data
"""
module Requests

import Genie, Genie.Router, Genie.Input
import HTTP, Reexport

export jsonpayload, rawpayload, filespayload, postpayload, getpayload
export request, getrequest, matchedroute, matchedchannel, wsclient
export infilespayload, filename, payload, peer


"""
    jsonpayload()

Processes an `application/json` `POST` request.
If it fails to successfully parse the `JSON` data it returns `nothing`. The original payload can still be accessed invoking `rawpayload()`
"""
function jsonpayload()
  Router.params(Genie.PARAMS_JSON_PAYLOAD)
end


"""
    jsonpayload(v)

Processes an `application/json` `POST` request attempting to return value corresponding to key v.
"""
function jsonpayload(v)
  jsonpayload()[v]
end


"""
    rawpayload() :: String

Returns the raw `POST` payload as a `String`.
"""
function rawpayload() :: String
  Router.params(Genie.PARAMS_RAW_PAYLOAD)
end


"""
    filespayload() :: Dict{String,HttpFile}

Collection of form uploaded files.
"""
function filespayload() :: Dict{String,Input.HttpFile}
  Router.params(Genie.PARAMS_FILES)
end


"""
    filespayload(filename::Union{String,Symbol}) :: HttpFile

Returns the `HttpFile` uploaded through the `key` input name.
"""
function filespayload(key::Union{String,Symbol}) :: Input.HttpFile
  Router.params(Genie.PARAMS_FILES)[string(key)]
end


"""
    infilespayload(key::Union{String,Symbol}) :: Bool

Checks if the collection of uploaded files contains a file stored under the `key` name.
"""
function infilespayload(key::Union{String,Symbol}) :: Bool
  haskey(filespayload(), string(key))
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
    postpayload() :: Dict{Symbol,Any}

A dict representing the POST variables payload of the request (corresponding to a `form-data` request)
"""
function postpayload() :: Dict{Symbol,Any}
  Router.params(Genie.PARAMS_POST_KEY)
end


"""
    postpayload(key::Symbol) :: Any

Returns the value of the POST variables `key`.
"""
function postpayload(key::Symbol)
  postpayload()[key]
end


"""
    postpayload(key::Symbol, default::Any)

Returns the value of the POST variables `key` or the `default` value if `key` is not defined.
"""
function postpayload(key::Symbol, default::Any)
  haskey(postpayload(), key) ? postpayload(key) : default
end


"""
    getpayload() :: Dict{Symbol,Any}

A dict representing the GET/query variables payload of the request (the part correspoding to `?foo=bar&baz=moo`)
"""
function getpayload() :: Dict{Symbol,Any}
  Router.params(Genie.PARAMS_GET_KEY)
end


"""
    getpayload(key::Symbol) :: Any

The value of the GET/query variable `key`, as in `?key=value`
"""
function getpayload(key::Symbol) :: Any
  getpayload()[key]
end


"""
    getpayload(key::Symbol, default::Any) :: Any

The value of the GET/query variable `key`, as in `?key=value`. If `key` is not defined, `default` is returned.
"""
function getpayload(key::Symbol, default::Any) :: Any
  haskey(getpayload(), key) ? getpayload(key) : default
end


"""
    request() :: HTTP.Request

Returns the raw HTTP.Request object associated with the request.
"""
function request() :: HTTP.Request
  Router.params(Genie.PARAMS_REQUEST_KEY)
end

const getrequest = request

"""
    payload() :: Any

Utility function for accessing the `params` collection, which holds the request variables.
"""
function payload() :: Dict
  Router.params()
end


"""
    payload(key::Symbol) :: Any

Utility function for accessing the `key` value within the `params` collection of request variables.
"""
function payload(key::Symbol) :: Any
  Router.params()[key]
end


"""
    payload(key::Symbol, default_value::T) :: Any

Utility function for accessing the `key` value within the `params` collection of request variables.
If `key` is not defined, `default_value` is returned.
"""
function payload(key::Symbol, default_value::T)::T where {T}
  haskey(Router.params(), key) ? Router.params()[key] : default_value
end


"""
    matchedroute() :: Route

Returns the `Route` object which was matched for the current request.
"""
function matchedroute() :: Genie.Router.Route
  Router.params(Genie.PARAMS_ROUTE_KEY)
end


"""
    matchedchannel() :: Channel

Returns the `Channel` object which was matched for the current request.
"""
function matchedchannel() :: Genie.Router.Channel
  Router.params(Genie.PARAMS_CHANNELS_KEY)
end


"""
    wsclient() :: HTTP.WebSockets.WebSocket

The web sockets client for the current request.
"""
function wsclient() :: HTTP.WebSockets.WebSocket
  Router.params(Genie.PARAMS_WS_CLIENT)
end


"""
    wtclient() :: HTTP.WebSockets.WebSocket

The web sockets client for the current request.
"""
function wtclient() :: UInt
  Router.params(:wtclient) |> hash
end


function getheaders(req::HTTP.Request) :: Dict{String,String}
  Dict{String,String}(req.headers)
end
function getheaders() :: Dict{String,String}
  getheaders(getrequest())
end


"""
    function peer()

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


end