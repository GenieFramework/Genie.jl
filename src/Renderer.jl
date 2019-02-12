module Renderer

export respond, json, redirect_to, html, flax, include_asset, has_requested, css_asset, js_asset
export respond_with_json, respond_with_html, respond_with, html!, json!, http_error, error!

using Nullables, JSON, HTTP
using Genie, Genie.Util, Genie.Configuration, Genie.Loggers, Genie.Macros

eval(:(include("$(Genie.config.html_template_engine).jl")))
Genie.config.html_template_engine != Genie.config.json_template_engine && Core.eval(:(include("$(Genie.config.json_template_engine).jl")))

eval(:(using .$(Genie.config.html_template_engine), .$(Genie.config.json_template_engine)))
eval(:(const HTMLTemplateEngine = $(Genie.config.html_template_engine)))
eval(:(const JSONTemplateEngine = $(Genie.config.json_template_engine)))

export HTMLTemplateEngine, JSONTemplateEngine

const DEFAULT_LAYOUT_FILE = Genie.config.renderer_default_layout_file

const CONTENT_TYPES = Dict{Symbol,String}(
  :html       => "text/html",
  :plain      => "text/plain",
  :text       => "text/plain",
  :json       => "application/json",
  :js         => "application/javascript",
  :javascript => "application/javascript",
  :xml        => "text/xml",
)
const DEFAULT_CONTENT_TYPE = :html


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
    Genie.Router.error_404(err.msg)
  elseif lowercase(string(response_type)) == "json"
    respond(Dict(:json => JSON.json(err)), 404, Dict{String,String}("Content-Type" => "application/json"))
  end
end


"""
    html(resource::Symbol, action::Symbol, layout::Symbol = DEFAULT_LAYOUT_FILE, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}

Invokes the HTML renderer of the underlying configured templating library.
"""
function html(resource::Symbol, action::Symbol, layout::Symbol = DEFAULT_LAYOUT_FILE; vars...) :: Dict{Symbol,String}
  HTMLTemplateEngine.render_html(resource, action, layout; vars...)
end
function html(view::String, layout::String = "<? @yield ?>"; vars...) :: Dict{Symbol,String}
  HTMLTemplateEngine.render_html(view, layout; vars...)
end


"""
    respond_with_html(resource::Symbol, action::Symbol, layout::Symbol = DEFAULT_LAYOUT_FILE, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response

Invokes the HTML renderer of the underlying configured templating library and wraps it into a `HTTP.Response`.
"""
function respond_with_html(resource::Symbol, action::Symbol, layout::Symbol = DEFAULT_LAYOUT_FILE; vars...) :: HTTP.Response
  html(resource, action, layout; vars...) |> respond
end
function respond_with_html(view::String, layout::String; vars...) :: HTTP.Response
  html(view, layout; vars...) |> respond
end
const html! = respond_with_html


function html!(output::String) :: HTTP.Response
  respond(output)
end


function flax(resource::Union{Symbol,String}, action::Union{Symbol,String}, layout::Union{Symbol,String} = DEFAULT_LAYOUT_FILE; vars...) :: Dict{Symbol,String}
  HTMLTemplateEngine.render_flax(resource, action, layout; vars...)
end


"""
    json(resource::Symbol, action::Symbol, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}

Invokes the JSON renderer of the underlying configured templating library.
"""
function json(resource::Union{Symbol,String}, action::Union{Symbol,String}; vars...) :: Dict{Symbol,String}
  JSONTemplateEngine.render_json(resource, action; vars...)
end


"""
    respond_with_json(resource::Symbol, action::Symbol, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Response

Invokes the JSON renderer of the underlying configured templating library and wraps it into a `HTTP.Response`.
"""
function respond_with_json(resource::Union{Symbol,String}, action::Union{Symbol,String}; vars...) :: HTTP.Response
  json(resource, action; vars...) |> respond
end
const json! = respond_with_json


function json!(output::String) :: HTTP.Response
  respond(output, :json)
end
function json!(output::Any) :: HTTP.Response
  JSON.json(output) |> json!
end


"""
    redirect_to(location::String, code::Int = 302, headers = Dict{String,String}()) :: Response

Sets redirect headers and prepares the `Response`.
"""
function redirect_to(location::String, code = 302, headers = Dict{String,String}()) :: HTTP.Response
  headers["Location"] = location
  respond(Dict{Symbol,String}(:plain => "Redirecting you to $location"), code, headers)
end
function redirect_to(named_route::Symbol, code = 302, headers = Dict{String,String}()) :: HTTP.Response
  redirect_to(Genie.Router.link_to(named_route), code, headers)
end


"""
    has_requested(content_type::Symbol) :: Bool

Checks wheter or not the requested content type matches `content_type`.
"""
function has_requested(content_type::Symbol) :: Bool
  task_local_storage(:__params)[:response_type] == content_type
end


"""
    respond{T}(body::Dict{Symbol,T}, code::Int = 200, headers = Dict{String,String}()) :: Response

Constructs a `Response` corresponding to the content-type of the request.
"""
function respond(body::Dict{Symbol,T}, code::Int = 200, headers = Dict{String,String}())::HTTP.Response where {T}
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
                      log("Unsupported Content-Type", :err)
                      log(body)
                      Loggers.@location

                      error("Unsupported Content-Type")
                    end

                    HTTP.Response(code, [h for h in headers], body = sbody)
end
function respond(body::String, content_type::Symbol) :: HTTP.Response
  HTTP.Response(200, ["Content-Type" => CONTENT_TYPES[content_type]], body = body)
end
function respond(body::String, content_type::String) :: HTTP.Response
  HTTP.Response(200, ["Content-Type" => content_type], body = body)
end
function respond(response::Tuple, headers = Dict{AbstractString,AbstractString}()) :: HTTP.Response
  respond(response[1], response[2], [h for h in headers])
end
function respond(response::HTTP.Response) :: HTTP.Response
  response
end
function respond(body::String, params::Dict{Symbol,T})::HTTP.Response where {T}
  r = params[:RESPONSE]
  r.data = body

  r |> respond
end
function respond(body::String) :: HTTP.Response
  respond(HTTP.Response(body))
end
function respond(args...; kargs...) :: HTTP.Response
  respond_with(Genie.Router.response_type(), args...; kargs...)
end
function respond(err::T)::HTTP.Response where {T<:Exception}
  respond_with(Genie.Router.response_type(), err)
end


"""
    http_error(status_code; id = "resource_not_found", code = "404-0001", title = "Not found", detail = "The requested resource was not found")

Constructs an error `Response`.
"""
function http_error(status_code; id = "", code = "", title = "", msg = "") :: HTTP.Response
  respond(msg, status_code, Dict{String,String}())
end
const error! = http_error


"""
    include_asset(asset_type::Symbol, file_name::String; fingerprinted = Genie.config.assets_fingerprinted) :: String

Returns the path to an asset. `asset_type` can be one of `:js`, `:css`. `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicated wheter or not fingerprinted (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function include_asset(asset_type::Symbol, file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String
  suffix = fingerprinted ? "-" * Genie.ASSET_FINGERPRINT * ".$(asset_type)" : ".$(asset_type)"
  "/$asset_type/$(file_name)$(suffix)"
end
function include_asset(asset_type::Symbol, file_name::Symbol; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String
  include_asset(asset_type, string(file_name), fingerprinted = fingerprinted)
end


"""
    css_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String

Path to a css asset. `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicated wheter or not fingerprinted (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function css_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String
  include_asset(:css, file_name, fingerprinted = fingerprinted)
end


"""
    js_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String

Path to a js asset. `file_name` should not include the extension.
`fingerprinted` is a `Bool` indicated wheter or not fingerprinted (unique hash) should be added to the asset's filename (used in production to invalidate caches).
"""
function js_asset(file_name::String; fingerprinted::Bool = Genie.config.assets_fingerprinted) :: String
  include_asset(:js, file_name, fingerprinted = fingerprinted)
end


end
