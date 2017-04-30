module Renderer

export respond, json, redirect_to, html, flax, include_asset, has_requested, css_asset, js_asset, json_pagination
export respond_with_json, respond_with_html
export error_404, error_500, error_XXX

using Genie, Util, JSON, Configuration, HttpServer, App, Router, Logger, Macros

if IS_IN_APP
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


"""
    html(resource::Symbol, action::Symbol, layout::Symbol = :app, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}

Invokes the HTML renderer of the underlying configured templating library.
"""
function html(resource::Symbol, action::Symbol, layout::Symbol = :app, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  HTMLTemplateEngine.html(resource, action, layout; parse_vars(vars)...)
end


"""
    respond_with_html(resource::Symbol, action::Symbol, layout::Symbol = :app, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response

Invokes the HTML renderer of the underlying configured templating library and wraps it into a `HttpServer.Response`.
"""
function respond_with_html(resource::Symbol, action::Symbol, layout::Symbol = :app, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response
  html(resource, action, layout, check_nulls; vars...) |> respond
end

function flax(resource::Symbol, action::Symbol, layout::Symbol = :app, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  HTMLTemplateEngine.flax(resource, action, layout; parse_vars(vars)...)
end


"""
    json(resource::Symbol, action::Symbol, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}

Invokes the JSON renderer of the underlying configured templating library.
"""
function json(resource::Symbol, action::Symbol, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  JSONTemplateEngine.json(resource, action; parse_vars(vars)...)
end


"""
    respond_with_json(resource::Symbol, action::Symbol, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response

Invokes the JSON renderer of the underlying configured templating library and wraps it into a `HttpServer.Response`.
"""
function respond_with_json(resource::Symbol, action::Symbol, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response
  json(resource, action, check_nulls; vars...) |> respond
end


"""
    redirect_to(location::String, code::Int = 302, headers = Dict{AbstractString,AbstractString}()) :: Response

Sets redirect headers and prepares the `Response`.
"""
function redirect_to(location::String, code::Int = 302, headers = Dict{AbstractString,AbstractString}()) :: Response
  headers["Location"] = location
  respond(Dict{Symbol,AbstractString}(:plain => "Redirecting you to $location"), code, headers)
end


"""
    has_requested(content_type::Symbol) :: Bool

Checks wheter or not the requested content type matches `content_type`.
"""
function has_requested(content_type::Symbol) :: Bool
  task_local_storage(:__params)[:response_type] == content_type
end


"""
    respond{T}(body::Dict{Symbol,T}, code::Int = 200, headers = Dict{AbstractString,AbstractString}()) :: Response

Constructs a `Response` corresponding to the content-type of the request.
"""
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


"""
    http_error(status_code; id = "resource_not_found", code = "404-0001", title = "Not found", detail = "The requested resource was not found")

Constructs an error `Response`.
"""
function http_error(status_code; id = "resource_not_found", code = "404-0001", title = "Not found", detail = "The requested resource was not found")
  respond(detail, status_code, Dict{AbstractString,AbstractString}())
end


"""
    error_404() :: Tuple{Int,Dict{AbstractString,AbstractString},String}

Reads the default 404 error page and returns it in a `Response` compatible Tuple.
"""
function error_404() :: Tuple{Int,Dict{AbstractString,AbstractString},String}
  error_page =  open(Genie.DOC_ROOT_PATH * "/error-404.html") do f
                  readstring(f)
                end
  (404, Dict{AbstractString,AbstractString}(), error_page)
end


"""
    error_500() :: Tuple{Int,Dict{AbstractString,AbstractString},String}

Reads the default 500 error page and returns it in a `Response` compatible Tuple.
"""
function error_500() :: Tuple{Int,Dict{AbstractString,AbstractString},String}
  error_page =  open(Genie.DOC_ROOT_PATH * "/error-500.html") do f
                  readstring(f)
                end
  (500, Dict{AbstractString,AbstractString}(), error_page)
end


"""
    error_XXX() :: Tuple{Int,Dict{AbstractString,AbstractString},String}

Reads the default XXX error page and returns it in a `Response` compatible Tuple.
"""
function error_XXX(xxx::Int) :: Tuple{Int,Dict{AbstractString,AbstractString},String}
  error_page =  open(Genie.DOC_ROOT_PATH * "/error-$xxx.html") do f
                  readstring(f)
                end
  (xxx, Dict{AbstractString,AbstractString}(), error_page)
end


"""
    css_asset(file_name::String) :: String
    js_asset(file_name::String) :: String
    include_asset(asset_type::Symbol, file_name::String) :: String

Returns the path to an asset as a file.
"""
function include_asset(asset_type::Symbol, file_name::String) :: String
  "/$asset_type/$file_name"
end
function css_asset(file_name::String) :: String
  include_asset(:css, file_name)
end
function js_asset(file_name::String) :: String
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
