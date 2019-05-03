module Renderer

export respond, html, html!, json, json!, redirect_to, has_requested
export http_error, error!

using Nullables, JSON, HTTP, Reexport
using Genie, Genie.Util, Genie.Configuration, Genie.Loggers

@reexport using Genie.Flax

const CONTENT_TYPES = Dict{Symbol,String}(
  :html       => "text/html",
  :plain      => "text/plain",
  :text       => "text/plain",
  :json       => "application/json",
  :js         => "application/javascript",
  :javascript => "application/javascript",
  :xml        => "text/xml",
  :markdown   => "text/markdown"
)
const DEFAULT_CONTENT_TYPE = :html

### HTML RENDERING ###

"""
"""
function html(resource::Union{Symbol,String}, action::Union{Symbol,String}; layout::Union{Symbol,String} = Genie.config.renderer_default_layout_file, context::Module = @__MODULE__, vars...) :: Dict{Symbol,HTMLString}
  Dict(:html => (Flax.html_renderer(resource, action; layout = layout, mod = context, vars...) |> Base.invokelatest))
end
function html!(resource::Union{Symbol,String}, action::Union{Symbol,String}; layout::Union{Symbol,String} = Genie.config.renderer_default_layout_file, context::Module = @__MODULE__, vars...) :: HTTP.Response
  html(resource, action; layout = layout, context = context, vars...) |> respond
end

### JSON RENDERING ###

"""
    json(resource::Symbol, action::Symbol, check_nulls::Vector{Pair{Symbol,Nullable}} = Vector{Pair{Symbol,Nullable}}(); vars...) :: Dict{Symbol,String}

Invokes the JSON renderer of the underlying configured templating library.
"""
function json(resource::Union{Symbol,String}, action::Union{Symbol,String}; context::Module = @__MODULE__, vars...) :: Dict{Symbol,JSONString}
  Dict(:json => Flax.json_renderer(resource, action; mod = context, vars...) |> Base.invokelatest)
end
function json!(resource::Union{Symbol,String}, action::Union{Symbol,String}; context::Module = @__MODULE__, vars...) :: HTTP.Response
  json(resource, action; mod = context, vars...) |> respond
end

### REDIRECT RESPONSES ###

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

### RESPONSES ###

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
                    elseif haskey(body, :markdown)
                      headers["Content-Type"] = CONTENT_TYPES[:markdown]
                      body[:markdown]
                    else
                      error("Unsupported Content-Type")
                    end

  HTTP.Response(code, [h for h in headers], body = sbody)
end
function respond(response::HTTP.Response) :: HTTP.Response
  response
end
function respond(body::String, params::Dict{Symbol,T})::HTTP.Response where {T}
  r = params[:RESPONSE]
  r.data = body

  r |> respond
end
function respond(args...; kargs...) :: HTTP.Response
  respond_with(Genie.Router.response_type(), args...; kargs...)
end
function respond(err::T)::HTTP.Response where {T<:Exception}
  respond_with(Genie.Router.response_type(), err)
end

### Dict pre-responses ###

function respond(body::String, content_type::Symbol = :html) :: Dict{Symbol,String}
  respond(Dict(content_type => body), 200, ["Content-Type" => CONTENT_TYPES[content_type]])
end

### ASSETS ###

"""
    http_error(status_code; id = "resource_not_found", code = "404-0001", title = "Not found", detail = "The requested resource was not found")

Constructs an error `Response`.
"""
function http_error(status_code; id = "", code = "", title = "", msg = "") :: HTTP.Response
  respond(Dict(Genie.Router.response_type() => msg), status_code, Dict{String,String}())
end
const error! = http_error


end
