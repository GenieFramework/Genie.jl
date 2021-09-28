"""
Collection of utilities for working with Responses data
"""
module Responses
using DocStringExtensionsMock

import Genie, Genie.Router
import HTTP

export getresponse, getheaders, setheaders, setheaders!, getstatus, setstatus, setstatus!, getbody, setbody, setbody!


"""
$TYPEDSIGNATURES
"""
function getresponse() :: HTTP.Response
  Router.params(Genie.PARAMS_RESPONSE_KEY)
end


"""
$TYPEDSIGNATURES
"""
function getheaders(res::HTTP.Response) :: Dict{String,String}
  Dict{String,String}(res.headers)
end
"""
$TYPEDSIGNATURES
"""
function getheaders() :: Dict{String,String}
  getheaders(getresponse())
end


"""
$TYPEDSIGNATURES
"""
function setheaders!(res::HTTP.Response, headers::Dict) :: HTTP.Response
  push!(res.headers, [headers...]...)

  res
end
"""
$TYPEDSIGNATURES
"""
function setheaders(headers::Dict) :: HTTP.Response
  setheaders!(getresponse(), headers)
end
"""
$TYPEDSIGNATURES
"""
function setheaders(header::Pair{String,String}) :: HTTP.Response
  setheaders(Dict(header))
end
"""
$TYPEDSIGNATURES
"""
function setheaders(headers::Vector{Pair{String,String}}) :: HTTP.Response
  setheaders(Dict(headers...))
end


"""
$TYPEDSIGNATURES
"""
function getstatus(res::HTTP.Response) :: Int
  res.status
end
"""
$TYPEDSIGNATURES
"""
function getstatus() :: Int
  getstatus(getresponse())
end


"""
$TYPEDSIGNATURES
"""
function setstatus!(res::HTTP.Response, status::Int) :: HTTP.Response
  res.status = status

  res
end
"""
$TYPEDSIGNATURES
"""
function setstatus(status::Int) :: HTTP.Response
  setstatus!(getresponse(), status)
end


"""
$TYPEDSIGNATURES
"""
function getbody(res::HTTP.Response) :: String
  String(res.body)
end
"""
$TYPEDSIGNATURES
"""
function getbody() :: String
  getbody(getresponse())
end


"""
$TYPEDSIGNATURES
"""
function setbody!(res::HTTP.Response, body::String) :: HTTP.Response
  res.body = collect(body)

  res
end
"""
$TYPEDSIGNATURES
"""
function setbody(body::String) :: HTTP.Response
  setbody!(getresponse(), body)
end

end
