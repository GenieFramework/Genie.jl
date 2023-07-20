"""
Collection of utilities for working with Responses data
"""
module Responses

import Genie, Genie.Router
import HTTP, OrderedCollections
using Genie.Context

export getresponse, getheaders, setheaders, setheaders!, getstatus, setstatus, getbody, setbody


function getresponse(params::Genie.Context.Params) :: HTTP.Response
  params[:response]
end


function getheaders(params::Genie.Context.Params) :: Pair{String,String}
  params[:response].headers
end


function setheaders!(res::HTTP.Response, headers::D)::HTTP.Response where D<:AbstractDict
  push!(res.headers, [headers...]...)

  res
end
function setheaders(params::Genie.Context.Params, headers::D)::Params where D<:AbstractDict
  params[:response] = setheaders!(params[:response], headers)
  params
end
function setheaders(params::Genie.Context.Params, header::Pair{String,String}) :: Genie.Context.Params
  params = setheaders(params, Dict(header))
end
function setheaders(params::Genie.Context.Params, headers::Vector{Pair{String,String}}) :: Genie.Context.Params
  params = setheaders(params, Dict(headers...))
end


function getstatus(params::Genie.Context.Params) :: Int
  params[:response].status
end


function setstatus(params::Genie.Context.Params, status::Int) :: Genie.Context.Params
  (params[:response]).status = status
  params
end


function getbody(params::Genie.Context.Params) :: String
  String(params[:response].body)
end


function setbody(params::Genie.Context.Params, body::String) :: Genie.Context.Params
  params[:response].body = collect(body)
  params
end

end
