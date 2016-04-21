module Render

module JSONAPI

using Render
using Jinnie

export json_builder, json, data, attributes

const EXT = "json.jl"
const SCOPED_VAR_NAME = :__render__item__in__scope__

function json(resource::Symbol, action::Symbol; vars...)
  for arg in vars
    k, v = arg
    spawn_vars(k, v)
  end
  include(abspath(joinpath("app", "resources", string(resource), "views", string(action) * ".$EXT")))
end

function json_builder(; params...)
  response = Dict()
  for p in params 
    response[p[1]] = p[2]
  end

  JSON.json(response)
end

function data(resources; structure...)
  data_items = []
  for resource in resources 
    spawn_vars(SCOPED_VAR_NAME, resource)
    push!(data_items, structure_to_dict(structure, resource))
  end

  data_items
end

function attributes(; structure...)
  () -> structure_to_dict(structure, eval(:(SCOPED_VAR_NAME)))
end

function spawn_vars(key, value)
  eval(current_module(), :($key = $value))
end

function structure_to_dict(structure, resource)
  data_item = Dict()
  for (k, v) in structure 
    k = endswith(string(k), "_") ? Symbol(string(k)[1:end-1]) : k
    data_item[Symbol(k)] =  if isa(v, Symbol) 
                              getfield(current_module().eval(resource), v) |> Util.expand_nullable
                            elseif isa(v, Function)
                              v()
                            else
                              v 
                            end
  end

  data_item
end

end # end module Render.JSONAPI

end # end module Render