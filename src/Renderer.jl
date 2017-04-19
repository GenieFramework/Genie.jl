module Renderer

export respond, json, redirect_to, html, flax, include_asset, has_requested, css_asset, js_asset, json_pagination
export respond_with_json, respond_with_html
export error_404, error_500, error_XXX

using Genie, Util, JSON, Configuration, HttpServer, App, Router, Logger, Macros

if isdefined(Genie, :config)
  eval(:(using $(Genie.config.html_template_engine), $(Genie.config.json_template_engine)))
  eval(:(const HTMLTemplateEngine = $(Genie.config.html_template_engine)))
  eval(:(const JSONTemplateEngine = $(Genie.config.json_template_engine)))

  export HTMLTemplateEngine, JSONTemplateEngine
end

const CONTENT_TYPES = Dict{Symbol,String}(
  :html   => "text/html",
  :plain  => "text/plain",
  :json   => "application/json",
  :js     => "text/javascript",
  :xml    => "text/xml",
)

const VIEWS_FOLDER = "views"
const LAYOUTS_FOLDER = "layouts"

function html(resource::Symbol, action::Symbol, layout::Symbol = :app, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  HTMLTemplateEngine.html(resource, action, layout; parse_vars(vars)...)
end

function respond_with_html(resource::Symbol, action::Symbol, layout::Symbol = :app, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response
  html(resource, action, layout, check_nulls; vars...) |> respond
end

function flax(resource::Symbol, action::Symbol, layout::Symbol = :app, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  HTMLTemplateEngine.flax(resource, action, layout; parse_vars(vars)...)
end

function json(resource::Symbol, action::Symbol, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  JSONTemplateEngine.json(resource, action; parse_vars(vars)...)
end

function respond_with_json(resource::Symbol, action::Symbol, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response
  json(resource, action, check_nulls; vars...) |> respond
end

function redirect_to(location::String, code::Int = 302, headers = Dict{AbstractString,AbstractString}()) :: Response
  headers["Location"] = location
  respond(Dict{Symbol,AbstractString}(:plain => "Redirecting you to $location"), code, headers)
end

function has_requested(content_type::Symbol)
  task_local_storage(:__params)[:response_type] == content_type
end

function respond{T}(body::Dict{Symbol,T}, code::Int = 200, headers = Dict{AbstractString,AbstractString}()) :: Response
  sbody::String =   if haskey(body, :json)
                      headers["Content-Type"] = CONTENT_TYPES[:json]
                      body[:json]
                    elseif haskey(body, :html)
                      headers["Content-Type"] = CONTENT_TYPES[:html]
                      body[:html]
                    elseif haskey(body, :js)
                      headers["Content-Type"] = CONTENT_TYPES[:js]
                      body[:js]
                    elseif haskey(body, :plain)
                      headers["Content-Type"] = CONTENT_TYPES[:plain]
                      body[:plain]
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
function css_asset(file_name::String)
  include_asset(:css, file_name)
end
function js_asset(file_name::String)
  include_asset(:js, file_name)
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

function json_pagination(path::AbstractString, total_items::Int; current_page::Int = 1, page_size::Int = Genie.config.pagination_jsonapi_default_items_per_page)
  page_param_name = "page"

  pg = Dict{Symbol,String}()
  pg[:first] = path

  pg[:first] = path * "?" * page_param_name * "[number]=1&" * page_param_name * "[size]=" * string(page_size)

  if current_page > 1
    pg[:prev] = path * "?" * page_param_name * "[number]=" * string(current_page - 1) * "&" * page_param_name * "[size]=" * string(page_size)
  end

  if current_page * page_size < total_items
    pg[:next] = path * "?" * page_param_name * "[number]=" * string(current_page + 1) * "&" * page_param_name * "[size]=" * string(page_size)
  end

  pg[:last] = path * "?" * page_param_name * "[number]=" * string(Int(ceil(total_items / page_size))) * "&" * page_param_name * "[size]=" * string(page_size)

  pg
end

end
