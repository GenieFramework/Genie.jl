"""
Collection of utilities for working with Responses data
"""
module Responses

import Genie, Genie.Router, Genie.Context
import HTTP, OrderedCollections

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
function setheaders(params::Genie.Context.Params, header::Pair{String,String}) :: Params
  params[:response] = setheaders(params, Dict(header))
  params
end
function setheaders(params::Genie.Context.Params, headers::Vector{Pair{String,String}}) :: Params
  params[:response] = setheaders(params, Dict(headers...))
  params
end


function getstatus(params::Genie.Context.Params) :: Int
  params[:res].status
end


function setstatus(params::Genie.Context.Params, status::Int) :: Params
  params[:res].status = status
  params
end


function getbody(params::Genie.Context.Params) :: String
  String(params[:res].body)
end


function setbody(params::Genie.Context.Params, body::String) :: Params
  params[:res].body = collect(body)
  params
end

end
