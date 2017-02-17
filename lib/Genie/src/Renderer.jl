module Renderer

export respond, json, redirect_to, html, flax, include_asset
export error_404, error_500, error_XXX

using Genie, Util, Macros, JSON, Configuration, HttpServer, App, Router, Logger

eval(:(using $(Genie.config.template_engine)))
eval(:(const TemplateEngine = $(Genie.config.template_engine)))
eval(:(export TemplateEngine))

@devtools()

const CONTENT_TYPES = Dict{Symbol,AbstractString}(
  :html   => "text/html",
  :plain  => "text/plain",
  :json   => "application/json",
  :js     => "text/javascript",
  :xml    => "text/xml",
)

const VIEWS_FOLDER = "views"
const LAYOUTS_FOLDER = "layouts"

function json(resource::Symbol, action::Symbol; vars...) :: Dict{Symbol,AbstractString}
  spawn_splatted_vars(vars)
  r = include(abspath(joinpath(Genie.RESOURCE_PATH, string(resource), VIEWS_FOLDER, string(action) * ".$RENDER_JSON_EXT")))

  Dict{Symbol,AbstractString}(:json => r)
end

function parse_vars(vars)
  pos_counter = 1
  for pair in vars
    if pair[1] != :check_nulls
      pos_counter += 1
      continue
    end

    for p in pair[2]
      if ! isa(p[2], Nullable)
        push!(vars, p[1] => p[2])
        continue
      end

      if isnull(p[2])
        return error_404()
      else
        push!(vars, p[1] => Base.get(p[2]))
      end
    end
  end

  vars
end

function html(resource::Symbol, action::Symbol, layout::Symbol = :app, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  TemplateEngine.html(resource, action, layout; parse_vars(vars)...)
end

function flax(resource::Symbol, action::Symbol, layout::Symbol = :app, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  TemplateEngine.flax(resource, action, layout; parse_vars(vars)...)
end

function redirect_to(location::String, code::Int = 302, headers = Dict{AbstractString,AbstractString}()) :: Response
  headers["Location"] = location
  respond(Dict{Symbol,AbstractString}(:plain => "Redirecting you to $location"), code, headers)
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
                              getfield(current_module().eval(resource), v) |> Base.get
                            elseif isa(v, Function)
                              v()
                            else
                              v
                            end
  end

  data_item
end

function respond{T}(body::Dict{Symbol,T}, code::Int = 200, headers = Dict{AbstractString,AbstractString}()) :: Response
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
                    else
                      Logger.log("Unsupported Content-Type", :err)
                      Logger.log(body)
                      Logger.@location

                      error("Unsupported Content-Type")
                    end

  Response(code, headers, sbody)
end
function respond(response::Tuple, headers = Dict{AbstractString,AbstractString}()) :: Response
  respond(response[1], response[2], headers)
end
function respond(response::Response) :: Response
  response
end
function respond{T}(body::String, params::Dict{Symbol,T}) :: Response
  r = params[:RESPONSE]
  r.data = body

  r |> respond
end
function respond(body::String) :: Response
  respond(Response(body))
end

function http_error(status_code; id = "resource_not_found", code = "404-0001", title = "Not found", detail = "The requested resource was not found")
  respond(detail, status_code, Dict{AbstractString,AbstractString}())
end

function error_404()
  error_page =  open(Genie.DOC_ROOT_PATH * "/error-404.html") do f
                  readstring(f)
                end
  (404, Dict{AbstractString,AbstractString}(), error_page)
end

function error_500()
  error_page =  open(Genie.DOC_ROOT_PATH * "/error-500.html") do f
                  readstring(f)
                end
  (500, Dict{AbstractString,AbstractString}(), error_page)
end

function error_XXX(xxx::Int)
  error_page =  open(Genie.DOC_ROOT_PATH * "/error-$xxx.html") do f
                  readstring(f)
                end
  (xxx, Dict{AbstractString,AbstractString}(), error_page)
end

function include_asset(asset_type::Symbol, file_name::String)
  "/$asset_type/$file_name"
end

# =================================================== #

module JSONAPI

using Renderer, Genie

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
