module Context

import HTTP, Reexport
import Genie: Input.HttpFile

Reexport.@reexport using OrderedCollections
export LittleDict, Params #, params, params!

mutable struct Params
  collection::LittleDict{Symbol, Any}
end

Base.Dict(params::Params) = params.collection
Base.getindex(params::Params, keys...) = getindex(params.collection, keys...)
function Base.setindex!(params::Params, value, key)
  params.collection[key] = value
end
Base.keys(params::Params) = keys(params.collection)
Base.values(params::Params) = values(params.collection)
Base.haskey(params::Params, key) = haskey(params.collection, key)
Base.get(params::Params, key, default) = get(params.collection, key, default)
Base.get!(params::Params, key, default) = get!(params.collection, key, default)

Params() = Params(setup_base_params())
Params(req::HTTP.Request, res::HTTP.Response) = Params(setup_base_params(req, res))

function (p::Params)(key::Symbol)
  p.collection[key]
end
function (p::Params)(key::Symbol, value)
  p.collection[key] = value
end


params(params::Params, key) = params[key]
params(params::Params, key, default) = get(params, key, default)
params!(params::Params, key, default) = get!(params, key, default)


"""
    setup_base_params(req::Request, res::Response, params::Dict) :: Dict

Populates `params` with default environment vars.
"""
function setup_base_params( req::HTTP.Request = HTTP.Request(),
                            res::Union{HTTP.Response,Nothing} = req.response,
                            params_collection::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()
                          )::LittleDict{Symbol,Any}
  LittleDict(
    params_collection...,
    :request    => req,
    :response   =>  if res === nothing
                      req.response = HTTP.Response()
                      req.response
                    else
                      res
                    end,
    :post       => get(params_collection, :post, LittleDict{Symbol,Any}()),
    :query      => get(params_collection, :query, LittleDict{Symbol,Any}()),
    :files      => get(params_collection, :files, LittleDict{String,HttpFile}()),
    :wsclient   => get(params_collection, :wsclient, nothing),
    :wtclient   => get(params_collection, :wtclient, nothing),
    :json       => get(params_collection, :json, nothing),
    :raw        => get(params_collection, :raw, ""),
    :route      => get(params_collection, :route, nothing),
    :channel    => get(params_collection, :channel, nothing),
    :mime       => get(params_collection, :mime, nothing),
  )
end

function setup_base_params(req::HTTP.Request, res::Union{HTTP.Response,Nothing}, params::Params) :: Params
  params.collection = setup_base_params(req, res, params.collection)
  params
end

end