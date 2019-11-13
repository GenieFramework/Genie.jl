"""
Collection of utilities for working with Requests data
"""
module Requests

import Genie, Genie.Router, Genie.Input
import HTTP, Reexport

export jsonpayload, rawpayload, filespayload, postpayload, getpayload, request, matchedroute, matchedchannel
export infilespayload, filename, payload
Reexport.@reexport using HTTP


"""
    jsonpayload()

Processes an `application/json` `POST` request.
If it fails to successfully parse the `JSON` data it returns `nothing`. The original payload can still be accessed invoking `rawpayload()`
"""
@inline function jsonpayload()
  Router.@params(Genie.PARAMS_JSON_PAYLOAD)
end


"""
    jsonpayload(::Type{T}) where {T}

Processes an `application/json` `POST` request attempting to convert the payload into a value of type `T`.
If it fails to successfully parse and convert the `JSON` data, it throws an exception. The original payload can still be accessed invoking `rawpayload()`
"""
@inline function jsonpayload(::Type{T})::T where {T}
  Router.@params(Genie.PARAMS_JSON_PAYLOAD)::T
end


"""
    rawpayload() :: String

Returns the raw `POST` payload as a `String`.
"""
@inline function rawpayload() :: String
  Router.@params(Genie.PARAMS_RAW_PAYLOAD)
end


"""
    filespayload() :: Dict{String,HttpFile}

Collection of form uploaded files.
"""
@inline function filespayload() :: Dict{String,Input.HttpFile}
  Router.@params(Genie.PARAMS_FILES)
end


"""
    filespayload(filename::Union{String,Symbol}) :: HttpFile

Returns the `HttpFile` uploaded through the `key` input name.
"""
@inline function filespayload(key::Union{String,Symbol}) :: Input.HttpFile
  Router.@params(Genie.PARAMS_FILES)[string(key)]
end


"""
    infilespayload(key::Union{String,Symbol}) :: Bool

Checks if the collection of uploaded files contains a file stored under the `key` name.
"""
@inline function infilespayload(key::Union{String,Symbol}) :: Bool
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
@inline function filename(file::Input.HttpFile) :: String
  file.name
end


"""
    postpayload() :: Dict{Symbol,Any}

A dict representing the POST variables payload of the request (corresponding to a `form-data` request)
"""
@inline function postpayload() :: Dict{Symbol,Any}
  Router.@params(Genie.PARAMS_POST_KEY)
end


"""
    postpayload(key::Symbol) :: Any

Returns the value of the POST variables `key`.
"""
@inline function postpayload(key::Symbol)
  postpayload()[key]
end


"""
    postpayload(key::Symbol, default::Any)

Returns the value of the POST variables `key` or the `default` value if `key` is not defined.
"""
@inline function postpayload(key::Symbol, default::Any)
  haskey(postpayload(), key) ? postpayload(key) : default
end


"""
    getpayload() :: Dict{Symbol,Any}

A dict representing the GET/query variables payload of the request (the part correspoding to `?foo=bar&baz=moo`)
"""
@inline function getpayload() :: Dict{Symbol,Any}
  Router.@params(Genie.PARAMS_GET_KEY)
end


"""
    getpayload(key::Symbol) :: Any

The value of the GET/query variable `key`, as in `?key=value`
"""
@inline function getpayload(key::Symbol) :: Any
  getpayload()[key]
end


"""
    getpayload(key::Symbol, default::Any) :: Any

The value of the GET/query variable `key`, as in `?key=value`. If `key` is not defined, `default` is returned.
"""
@inline function getpayload(key::Symbol, default::Any) :: Any
  haskey(getpayload(), key) ? getpayload(key) : default
end


"""
    request() :: HTTP.Request

Returns the raw HTTP.Request object associated with the request.
"""
@inline function request() :: HTTP.Request
  Router.@params(Genie.PARAMS_REQUEST_KEY)
end


"""
    payload() :: Any

Utility function for accessing the `@params` collection, which holds the request variables.
"""
@inline function payload() :: Dict
  Router.@params
end


"""
    payload(key::Symbol) :: Any

Utility function for accessing the `key` value within the `@params` collection of request variables.
"""
@inline function payload(key::Symbol) :: Any
  Router.@params()[key]
end


"""
    payload(key::Symbol, default_value::T) :: Any

Utility function for accessing the `key` value within the `@params` collection of request variables.
If `key` is not defined, `default_value` is returned.
"""
@inline function payload(key::Symbol, default_value::T)::T where {T}
  haskey(Router.@params(), key) ? Router.@params()[key] : default_value
end


"""
    matchedroute() :: Route

Returns the `Route` object which was matched for the current request.
"""
@inline function matchedroute() :: Genie.Router.Route
  Router.@params(Genie.PARAMS_ROUTE_KEY)
end


"""
    matchedchannel() :: Channel

Returns the `Channel` object which was matched for the current request.
"""
@inline function matchedchannel() :: Genie.Router.Channel
  Router.@params(Genie.PARAMS_CHANNELS_KEY)
end

end