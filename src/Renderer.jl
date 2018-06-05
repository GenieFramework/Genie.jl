module Renderer

export respond, json, redirect_to, html, flax, include_asset, has_requested, css_asset, js_asset
export respond_with_json, respond_with_html, respond_with

using Genie, Util, JSON, Genie.Configuration, HttpServer, App, Router, Logger, Macros

eval(:(using $(App.config.html_template_engine), $(App.config.json_template_engine)))
eval(:(const HTMLTemplateEngine = $(App.config.html_template_engine)))
eval(:(const JSONTemplateEngine = $(App.config.json_template_engine)))

export HTMLTemplateEngine, JSONTemplateEngine

const DEFAULT_LAYOUT_FILE = App.config.renderer_default_layout_file

const CONTENT_TYPES = Dict{Symbol,String}(
  :html   => "text/html",
  :plain  => "text/plain",
  :json   => "application/json",
  :js     => "text/javascript",
  :xml    => "text/xml",
)
const DEFAULT_CONTENT_TYPE = :html

const VIEWS_FOLDER = "views"
const LAYOUTS_FOLDER = "layouts"


"""
"""
function respond_with(response_type::Symbol, args...; kargs...)
  if lowercase(string(response_type)) == "html"
    respond_with_html(args...; kargs...)
  elseif lowercase(string(response_type)) == "json"
    respond_with_json(args...; kargs...)
  end
end
function respond_with(response_type::Symbol, err::T) where {T<:Exception}
  if lowercase(string(response_type)) == "html"
    error_404(err.msg)
  elseif lowercase(string(response_type)) == "json"
    respond(Dict(:json => JSON.json(err)), 404, Dict{AbstractString,AbstractString}("Content-Type" => "application/json"))
  end
end


"""
    html(resource::Symbol, action::Symbol, layout::Symbol = DEFAULT_LAYOUT_FILE, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}

Invokes the HTML renderer of the underlying configured templating library.
"""
function html(resource::Union{Symbol,String}, action::Union{Symbol,String}, layout::Union{Symbol,String} = DEFAULT_LAYOUT_FILE, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  HTMLTemplateEngine.html(resource, action, layout; parse_vars(vars)...)
end
function html(view::String, layout::String, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  HTMLTemplateEngine.html(view, layout; parse_vars(vars)...)
end


"""
    respond_with_html(resource::Symbol, action::Symbol, layout::Symbol = DEFAULT_LAYOUT_FILE, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response

Invokes the HTML renderer of the underlying configured templating library and wraps it into a `HttpServer.Response`.
"""
function respond_with_html(resource::Symbol, action::Symbol, layout::Union{Symbol,String} = DEFAULT_LAYOUT_FILE, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response
  html(resource, action, layout, check_nulls; vars...) |> respond
end
function respond_with_html(view::String, layout::String, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response
  html(view, layout, check_nulls; vars...) |> respond
end


function flax(resource::Union{Symbol,String}, action::Union{Symbol,String}, layout::Union{Symbol,String} = DEFAULT_LAYOUT_FILE, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  HTMLTemplateEngine.flax(resource, action, layout; parse_vars(vars)...)
end


"""
    json(resource::Symbol, action::Symbol, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}

Invokes the JSON renderer of the underlying configured templating library.
"""
function json(resource::Union{Symbol,String}, action::Union{Symbol,String}, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}
  JSONTemplateEngine.json(resource, action; parse_vars(vars)...)
end


"""
    respond_with_json(resource::Symbol, action::Symbol, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response

Invokes the JSON renderer of the underlying configured templating library and wraps it into a `HttpServer.Response`.
"""
function respond_with_json(resource::Union{Symbol,String}, action::Union{Symbol,String}, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response
  json(resource, action, check_nulls; vars...) |> respond
end


"""
    redirect_to(location::String, code::Int = 302, headers = Dict{AbstractString,AbstractString}()) :: Response

Sets redirect headers and prepares the `Response`.
"""
function redirect_to(location::String, code = 302, headers = Dict{AbstractString,AbstractString}()) :: Response
  headers["Location"] = location
  respond(Dict{Symbol,AbstractString}(:plain => "Redirecting you to $location"), code, headers)
end
function redirect_to(named_route::Symbol, code = 302, headers = Dict{AbstractString,AbstractString}()) :: Response
  redirect_to(link_to(named_route), code, headers)
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
function respond(body::Dict{Symbol,T}, code::Int = 200, headers = Dict{AbstractString,AbstractString}())::Response where {T}
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
# function respond(body::String, content_type::Union{Symbol,String})
function respond(body::String, content_type::Symbol) :: Response
  # content_type = isa(content_type, Symbol) ? CONTENT_TYPES[content_type] : content_type
  Response(200, Dict{AbstractString,AbstractString}("Content-Type" => CONTENT_TYPES[content_type]), body)
end
function respond(response::Tuple, headers = Dict{AbstractString,AbstractString}()) :: Response
  respond(response[1], response[2], headers)
end
function respond(response::Response) :: Response
  response
end
function respond(body::String, params::Dict{Symbol,T})::Response where {T}
  r = params[:RESPONSE]
  r.data = body

  r |> respond
end
function respond(body::String) :: Response
  respond(Response(body))
end
function respond(args...; kargs...) :: Response
  respond_with(response_type(), args...; kargs...)
end
function respond(err::T)::Response where {T<:Exception}
  respond_with(response_type(), err)
end


"""
    http_error(status_code; id = "resource_not_found", code = "404-0001", title = "Not found", detail = "The requested resource was not found")

Constructs an error `Response`.
"""
function http_error(status_code; id = "resource_not_found", code = "404-0001", title = "Not found", detail = "The requested resource was not found")
  respond(detail, status_code, Dict{AbstractString,AbstractString}())
end


"""
    include_asset(asset_type::Symbol, file_name::String; fingerprinted = App.config.assets_fingerprinted) :: String

Returns the path to an asset. `asset_type` can be one of `:js`, `:css`. `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicated wheter or not fingerprinted (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function include_asset(asset_type::Symbol, file_name::String; fingerprinted::Bool = App.config.assets_fingerprinted) :: String
  suffix = fingerprinted ? "-" * App.ASSET_FINGERPRINT * ".$(asset_type)" : ".$(asset_type)"
  "/$asset_type/$(file_name)$(suffix)"
end
function include_asset(asset_type::Symbol, file_name::Symbol; fingerprinted::Bool = App.config.assets_fingerprinted) :: String
  include_asset(asset_type, string(file_name), fingerprinted = fingerprinted)
end


"""
    css_asset(file_name::String; fingerprinted::Bool = App.config.assets_fingerprinted) :: String

Path to a css asset. `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicated wheter or not fingerprinted (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function css_asset(file_name::String; fingerprinted::Bool = App.config.assets_fingerprinted) :: String
  include_asset(:css, file_name, fingerprinted = fingerprinted)
end


"""
    js_asset(file_name::String; fingerprinted::Bool = App.config.assets_fingerprinted) :: String

Path to a js asset. `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicated wheter or not fingerprinted (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function js_asset(file_name::String; fingerprinted::Bool = App.config.assets_fingerprinted) :: String
  include_asset(:js, file_name, fingerprinted = fingerprinted)
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


end
