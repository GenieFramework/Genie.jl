"""
Collection of utilities for working with Responses data
"""
module Responses

import Genie, Genie.Router, Genie.Context
import HTTP, OrderedCollections

export getresponse, getheaders, setheaders, setheaders!, getstatus, setstatus, setstatus!, getbody, setbody, setbody!


function getresponse(params::Genie.Context.Params) :: HTTP.Response
  params[:response]
end


function getheaders(res::HTTP.Response) :: Pair{String,String}
  res.headers
end
function getheaders(params::Genie.Context.Params) :: Pair{String,String}
  getheaders(params[:response])
end


function setheaders!(res::HTTP.Response, headers::D)::HTTP.Response where D<:AbstractDict
  push!(res.headers, [headers...]...)

  res
end
function setheaders(params::Genie.Context.Params, headers::D)::HTTP.Response where D<:AbstractDict
  setheaders!(params[:response], headers)
end
function setheaders(params::Genie.Context.Params, header::Pair{String,String}) :: HTTP.Response
  setheaders(params, Dict(header))
end
function setheaders(params::Genie.Context.Params, headers::Vector{Pair{String,String}}) :: HTTP.Response
  setheaders(params, Dict(headers...))
end


function getstatus(res::HTTP.Response) :: Int
  res.status
end
function getstatus(params::Genie.Context.Params) :: Int
  getstatus(getresponse(params))
end


function setstatus!(res::HTTP.Response, status::Int) :: HTTP.Response
  res.status = status

  res
end
function setstatus(params::Genie.Context.Params, status::Int) :: HTTP.Response
  setstatus!(getresponse(params), status)
end


function getbody(res::HTTP.Response) :: String
  String(res.body)
end
function getbody(params::Genie.Context.Params) :: String
  getbody(getresponse(params))
end


function setbody!(res::HTTP.Response, body::String) :: HTTP.Response
  res.body = collect(body)

  res
end
function setbody(params::Genie.Context.Params, body::String) :: HTTP.Response
  setbody!(getresponse(params), body)
end

end
