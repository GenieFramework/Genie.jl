module Renderer
export respond, json, mustache, ejl, redirect_to
using Genie, Util, Macros, JSON, Ejl, Mustache, Configuration, HttpServer, App, Router
@devtools()

const CONTENT_TYPES = Dict{Symbol,AbstractString}(
  :html   => "text/html",
  :plain  => "text/plain",
  :json   => "text/json",
  :js     => "application/javascript",
)
const MUSTACHE_YIELD_VAR_NAME = :yield
const EJL_YIELD_VAR_NAME = :yield

function json(resource::Symbol, action::Symbol; vars...) :: Dict{Symbol,AbstractString}
  spawn_splatted_vars(vars)
  r = include(abspath(joinpath(Genie.RESOURCE_PATH, string(resource), "views", string(action) * ".$RENDER_JSON_EXT")))

  Dict(:json => r)
end

function ejl(resource::Symbol, action::Symbol; layout::Union{Symbol,AbstractString} = :app, render_layout::Bool = true, vars...) :: Dict{Symbol,AbstractString}
  spawn_splatted_vars(vars)

  path = abspath(joinpath(Genie.RESOURCE_PATH, string(resource), "views", string(action) * "." * Configuration.RENDER_EJL_EXT))
  r = @ejl(:($path))
  # r = Ejl.render_ejl(path)

  if render_layout
    spawn_vars(EJL_YIELD_VAR_NAME, r)
    path = abspath(joinpath(Genie.APP_PATH, "layouts", string(layout) * "." * Configuration.RENDER_EJL_EXT))
    r = @ejl(:($path))
  end

  Dict{Symbol,AbstractString}(:html => r)
end
function ejl(content::AbstractString, layout::Union{Symbol,AbstractString} = :app, vars...) :: Dict{Symbol,AbstractString}
  spawn_splatted_vars(vars)
  layout = Ejl.template_from_file(abspath(joinpath(Genie.APP_PATH, "layouts", string(layout) * "." * Configuration.RENDER_EJL_EXT)))
  spawn_vars(EJL_YIELD_VAR_NAME, content)
  r = Ejl.render_tpl(layout)

  Dict{Symbol,AbstractString}(:html => r)
end
function ejl(content::Vector{AbstractString}; vars...) :: AbstractString
  spawn_splatted_vars(vars)
  Ejl.render_tpl(content)
end

function mustache(resource::Symbol, action::Symbol; layout::Union{Symbol,AbstractString} = :app, render_layout::Bool = true, vars...) :: Dict{Symbol,AbstractString}
  spawn_splatted_vars(vars)

  template = Mustache.template_from_file(abspath(joinpath(Genie.RESOURCE_PATH, string(resource), "views", string(action) * ".$RENDER_MUSTACHE_EXT")))
  vals = merge(special_vals(), Dict(k => v for (k, v) in vars))
  r = Mustache.render(template, vals)

  if render_layout
    layout = Mustache.template_from_file(abspath(joinpath(Genie.APP_PATH, "layouts", string(layout) * ".$RENDER_MUSTACHE_EXT")))
    vals[MUSTACHE_YIELD_VAR_NAME] = r
    r = Mustache.render(layout, vals)
  end

  Dict{Symbol,AbstractString}(:html => r)
end
function mustache(content::AbstractString, layout::Union{Symbol,AbstractString} = :app, vars...) :: Dict{Symbol,AbstractString}
  spawn_splatted_vars(vars)
  vals = merge(special_vals(), Dict(k => v for (k, v) in vars))
  layout = Mustache.template_from_file(abspath(joinpath(Genie.APP_PATH, "layouts", string(layout) * ".$RENDER_MUSTACHE_EXT")))
  vals[MUSTACHE_YIELD_VAR_NAME] = content
  r = Mustache.render(layout, vals)

  Dict{Symbol,AbstractString}(:html => r)
end

function redirect_to(location::AbstractString, code::Int = 302, headers::Dict{AbstractString,AbstractString} = Dict{AbstractString,AbstractString}()) :: Dict{Symbol,AbstractString}
  headers["Location"] = location
  respond(Dict{Symbol,AbstractString}(:text => ""), code, headers)
end

function spawn_splatted_vars(vars, m::Module = current_module()) :: Void
  for arg in vars
    k, v = arg
    spawn_vars(k, v, m)
  end

  nothing
end

function rendered_spawn_splatted_vars{T}(vars::Dict{Symbol,T}, m::Module = current_module()) :: String
  spawn_splatted_vars(vars, m)
  ""
end

function special_vals() :: Dict{Symbol,Any}
  Dict{Symbol,Any}(
    :genie_assets_path => Genie.config.assets_path
  )
end

function spawn_vars(key, value, m::Module = current_module()) :: Void
  eval(m, :(const $key = $value))

  nothing
end

function structure_to_dict(structure, resource = nothing) :: Dict{Symbol,Any}
  data_item = Dict{Symbol,Any}()
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

function respond{T}(body::Dict{Symbol,T}, code::Int = 200, headers::Dict{AbstractString,AbstractString} = Dict{AbstractString,AbstractString}()) :: Tuple{Int,Dict{AbstractString,AbstractString},AbstractString}
  sbody::String =   if haskey(body, :json)
                      headers["Content-Type"] = CONTENT_TYPES[:json]
                      JSON.json(body[:json])
                    elseif haskey(body, :html)
                      headers["Content-Type"] = CONTENT_TYPES[:html]
                      string(body[:html])
                    elseif haskey(body, :js)
                      headers["Content-Type"] = CONTENT_TYPES[:js]
                      string(body[:js])
                    elseif haskey(body, :plain)
                      headers["Content-Type"] = CONTENT_TYPES[:plain]
                      string(body[:plain])
                    end

  (code, headers, sbody)
end
function respond(response::Tuple, headers::Dict{AbstractString,AbstractString} = Dict{AbstractString,AbstractString}()) :: Tuple{Int,Dict{AbstractString,AbstractString},Dict{Symbol,Any}}
  respond(response[1], response[2], headers)
end
function respond(response::Response) :: Response
  response
end
function respond(body::String, params::Dict{Symbol,Any}) :: Response
  r = params[:RESPONSE]
  r.data = body

  r |> respond
end
function respond(body::String) :: Response
  @show Router.params()[:RESPONSE].headers
  respond(body, Router.params())
end

function http_error(status_code; id = "resource_not_found", code = "404-0001", title = "Not found", detail = "The requested resource was not found")
  respond(detail, status_code, Dict{AbstractString,AbstractString}())
end

function error_404()
  error_page =  open(DOC_ROOT_PATH * "/error-404.html") do f
                  readstring(f)
                end
  (404, Dict{AbstractString,AbstractString}(), error_page)
end

# =================================================== #

module JSONAPI

using Renderer
using Genie

export builder, elem, pagination, @attr, attr

function builder(; params...)
  response = Dict()
  for p in params
    response[p[1]] =  if isa(p[2], Function)
                        p[2]()
                      else
                        p[2]
                      end
  end

  response
end

function elem(collection, instance_name; structure...)
  if ! isa(collection, Array)
    Renderer.spawn_vars(instance_name, collection)
    return Renderer.structure_to_dict(structure, collection)
  end

  data_items = []
  for resource in collection
    Renderer.spawn_vars(instance_name, resource)
    push!(data_items, Renderer.structure_to_dict(structure, resource))
  end

  data_items
end

function elem(instance_var; structure...)
  () -> Renderer.structure_to_dict(structure,  if isa(instance_var, Symbol)
                                                current_module().eval(instance_var)
                                              else
                                                instance_var
                                              end)
end

function elem(; structure...)
  () -> Renderer.structure_to_dict(structure)
end

function attr(expr)
  () -> expr
end

function http_error(status_code; id = "resource_not_found", code = "404-0001", title = "Not found", detail = "The requested resource was not found")
  Dict{Symbol, Any}(
    :errors => elem(
                      id        = id,
                      status    = status_code,
                      code      = code,
                      title     = title,
                      detail    = detail
                    )()
  ), status_code
end

function pagination(path::AbstractString, total_items::Int; current_page::Int = 1, page_size::Int = Genie.genie_app.config.pagination_default_items_per_page)
  pg = Dict{Symbol, AbstractString}()
  pg[:first] = path

  pg[:first] = path * "?page[number]=1&page[size]=" * string(page_size)

  if current_page > 1
    pg[:prev] = path * "?page[number]=" * string(current_page - 1) * "&page[size]=" * string(page_size)
  end

  if current_page * page_size < total_items
    pg[:next] = path * "?page[number]=" * string(current_page + 1) * "&page[size]=" * string(page_size)
  end

  pg[:last] = path * "?page[number]=" * string(Int(ceil(total_items / page_size))) * "&page[size]=" * string(page_size)

  pg
end

end # end module Renderer.JSONAPI
end # end module Render
