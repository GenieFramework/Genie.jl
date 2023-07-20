"""
Collection of utilities for working with Requests data
"""
module Requests

using Genie, Genie.Context
import Genie.Router, Genie.Input
import HTTP, Reexport
import Base: ImmutableDict
import OrderedCollections: LittleDict

export filename, peer, isajax, getheaders, request


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


function getheaders(params::Genie.Context.Params) :: ImmutableDict{<:AbstractString,<:AbstractString}
  ImmutableDict{String,String}(params[:req].headers)
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
    isajax(params::Params) :: Bool

Attempts to determine if a request is Ajax by sniffing the headers.
"""
function isajax(params::Genie.Context.Params) :: Bool
  req = params[:request]

  for (k,v) in getheaders(req)
    k = replace(k, r"_|-"=>"") |> lowercase
    occursin("requestedwith", k) && occursin("xmlhttp", lowercase(v)) && return true
  end

  return false
end


request(params::Params) = params[:request]

end
