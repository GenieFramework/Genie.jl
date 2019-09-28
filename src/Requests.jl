"""
Collection of utilities for working with Requests data
"""
module Requests

using Genie, Genie.Router, Genie.Input
using HTTP

export jsonpayload, rawpayload, filespayload, postpayload, getpayload, request, matchedroute, matchedchannel
export infilespayload, download, filename, payload, read


"""
    jsonpayload()

Processes an `application/json` `POST` request.
If it fails to successfully parse the `JSON` data it returns `nothing`. The original payload can still be accessed invoking `rawpayload()`
"""
@inline function jsonpayload()
  @params(Genie.PARAMS_JSON_PAYLOAD)
end


"""
    jsonpayload(::Type{T}) where {T}

Processes an `application/json` `POST` request attempting to convert the payload into a value of type `T`.
If it fails to successfully parse and convert the `JSON` data, it throws an exception. The original payload can still be accessed invoking `rawpayload()`
"""
@inline function jsonpayload(::Type{T})::T where {T}
  @params(Genie.PARAMS_JSON_PAYLOAD)::T
end


"""
    rawpayload() :: String

Returns the raw `POST` payload as a `String`.
"""
@inline function rawpayload() :: String
  @params(Genie.PARAMS_RAW_PAYLOAD)
end


"""
    filespayload() :: Dict{String,HttpFile}

Collection of form uploaded files.
"""
@inline function filespayload() :: Dict{String,HttpFile}
  @params(Genie.PARAMS_FILES)
end


"""
    filespayload(filename::Union{String,Symbol}) :: HttpFile

Returns the `HttpFile` uploaded through the `key` input name.
"""
@inline function filespayload(key::Union{String,Symbol}) :: HttpFile
  @params(Genie.PARAMS_FILES)[string(key)]
end


"""
    infilespayload(key::Union{String,Symbol}) :: Bool

Checks if the collection of uploaded files contains a file stored under the `key` name.
"""
@inline function infilespayload(key::Union{String,Symbol}) :: Bool
  haskey(filespayload(), string(key))
end


"""
    Base.download(file::HttpFile, name::String = file.name)

Saves uploaded `HttpFile` `file` to local storage under the `name` filename.
"""
@inline function Base.download(file::HttpFile, name::String = file.name) :: Int
  write(name, IOBuffer(file.data))
end


"""
    read(file::HttpFile)

Returns the content of `file` as string.
"""
@inline function Base.read(file::HttpFile, ::Type{String}) :: String
  file.data |> String
end


"""
    filename(file::HttpFile) :: String

Original filename of the uploaded `HttpFile` `file`.
"""
@inline function filename(file::HttpFile) :: String
  file.name
end


"""
    postpayload() :: Dict{Symbol,Any}

A dict representing the POST variables payload of the request (corresponding to a `form-data` request)
"""
@inline function postpayload() :: Dict{Symbol,Any}
  @params(Genie.PARAMS_POST_KEY)
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
  @params(Genie.PARAMS_GET_KEY)
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
  @params(Genie.PARAMS_REQUEST_KEY)
end


"""
    payload() :: Any

Utility function for accessing the `@params` collection, which holds the request variables.
"""
@inline function payload() :: Any
  @params
end


"""
    payload(key::Symbol) :: Any

Utility function for accessing the `key` value within the `@params` collection of request variables.
"""
@inline function payload(key::Symbol) :: Any
  @params()[key]
end


"""
    payload(key::Symbol, default_value::T) :: Any

Utility function for accessing the `key` value within the `@params` collection of request variables.
If `key` is not defined, `default_value` is returned.
"""
@inline function payload(key::Symbol, default_value::T)::T where {T}
  haskey(@params(), key) ? @params()[key] : default_value
end


"""
    matchedroute() :: Route

Returns the `Route` object which was matched for the current request.
"""
@inline function matchedroute() :: Genie.Router.Route
  @params(Genie.PARAMS_ROUTE_KEY)
end


"""
    matchedchannel() :: Channel

Returns the `Channel` object which was matched for the current request.
"""
@inline function matchedchannel() :: Genie.Router.Channel
  @params(Genie.PARAMS_CHANNELS_KEY)
end

end