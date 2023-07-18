module Context

import HTTP
import Genie: Input.HttpFile
using Base: ImmutableDict
using OrderedCollections: LittleDict

export ImmutableDict, Params

mutable struct Params
  collection::ImmutableDict{Symbol, Any}
end

Params() = Params(setup_base_params())
Params(req::HTTP.Request, res::HTTP.Response) = Params(setup_base_params(req, res))
function (p::Params)(key::Symbol)
  p.collection[key]
end

params(params::Params, key) = params[key]

Base.Dict(params::Params) = params.collection
Base.getindex(params::Params, keys...) = getindex(params.collection, keys...)

"""
    setup_base_params(req::Request, res::Response, params::Dict{Symbol,Any}) :: Dict{Symbol,Any}

Populates `params` with default environment vars.
"""
function setup_base_params( req::HTTP.Request = HTTP.Request(),
                            res::Union{HTTP.Response,Nothing} = req.response,
                            params_collection = ImmutableDict{Symbol,Any}()
                          )::ImmutableDict{Symbol,Any}
  ImmutableDict(
    params_collection,
    :request    => req,
    :response   =>  if res === nothing
                      req.response = HTTP.Response()
                      req.response
                    else
                      res
                    end,
    :post       => LittleDict{Symbol,Any}(),
    :query      => LittleDict{Symbol,Any}(),
    :files      => LittleDict{String,HttpFile}(),
    :wsclient   => nothing,
    :wtclient   => nothing,
    :json       => nothing,
    :raw        => "",
    :route      => nothing,
    :channel    => nothing,
    :mime       => nothing
  )
end

end