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
function html(resource::Union{Symbol,String}, action::Union{Symbol,String}; layout::Union{Symbol,String} = Genie.config.renderer_default_layout_file,
              context::Module = @__MODULE__, vars...) :: Dict{Symbol,HTMLString}
  Dict(:html => (Flax.html_renderer(resource, action; layout = layout, mod = context, vars...) |> Base.invokelatest))
end
function html(data::String; context::Module = @__MODULE__, vars...) :: Dict{Symbol,HTMLString}
  Dict(:html => (Flax.html_renderer(data; mod = context, vars...) |> Base.invokelatest))
end


"""
"""
function html!( resource::Union{Symbol,String}, action::Union{Symbol,String}; layout::Union{Symbol,String} = Genie.config.renderer_default_layout_file,
                context::Module = @__MODULE__, status::Int = 200, headers::Dict{String,String} = Dict{String,String}(), vars...) :: HTTP.Response
  respond(html(resource, action; layout = layout, context = context, vars...), status, headers)
end
function html!(data::String; context::Module = @__MODULE__, status::Int = 200, headers::Dict{String,String} = Dict{String,String}(), vars...) :: HTTP.Response
  respond(html(data; context = context, vars...), status, headers)
end

### JSON RENDERING ###

"""
Invokes the JSON renderer of the underlying configured templating library.
"""
function json(resource::Union{Symbol,String}, action::Union{Symbol,String}; context::Module = @__MODULE__, vars...) :: Dict{Symbol,JSONString}
  Dict(:json => Flax.json_renderer(resource, action; mod = context, vars...) |> Base.invokelatest)
end
function json(data) :: Dict{Symbol,JSONString}
  Dict(:json => JSON.json(data))
end


"""
"""
function json!(resource::Union{Symbol,String}, action::Union{Symbol,String}; context::Module = @__MODULE__, status::Int = 200, headers::Dict{String,String} = Dict{String,String}(), vars...) :: HTTP.Response
  respond(json(resource, action; mod = context, vars...), status, headers)
end
function json!(data; status::Int = 200, headers::Dict{String,String} = Dict{String,String}()) :: HTTP.Response
  respond(json(data), status, headers)
end

### REDIRECT RESPONSES ###

"""
    redirect_to(location::String, code::Int = 302, headers = Dict{String,String}()) :: Response

Sets redirect headers and prepares the `Response`.
"""
function redirect_to(location::String, code::Int = 302, headers::Dict{String,String} = Dict{String,String}()) :: HTTP.Response
  headers["Location"] = location
  respond(Dict{Symbol,String}(:plain => "Redirecting you to $location"), code, headers)
end
function redirect_to(named_route::Symbol, code::Int = 302, headers::Dict{String,String} = Dict{String,String}()) :: HTTP.Response
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
function respond(body::Dict{Symbol,T}, code::Int = 200, headers::Dict{String,String} = Dict{String,String}())::HTTP.Response where {T}
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
function respond(err::T, content_type::Union{Symbol,String} = Genie.Router.response_type(), code::Int = 500)::HTTP.Response where {T<:Exception}
  HTTP.Response(code, (isa(content_type, Symbol) ? ["Content-Type" => CONTENT_TYPES[content_type]] : ["Content-Type" => content_type]), body = string(err))
end
function respond(body::String, content_type::Union{Symbol,String} = Genie.Router.response_type(), code::Int = 200) :: HTTP.Response
  HTTP.Response(code, (isa(content_type, Symbol) ? ["Content-Type" => CONTENT_TYPES[content_type]] : ["Content-Type" => content_type]), body = body)
end
function respond(body, code::Int = 200, headers = Dict{String,String}())
  HTTP.Response(code, [h for h in headers], body = string(body))
end
function respond(f::Function, code::Int = 200, headers = Dict{String,String}())
  respond(f(), code, headers)
end

### ASSETS ###

"""
Constructs an error `Response`.
"""
function http_error(status_code; id = "", code = "", title = "", msg = "") :: HTTP.Response # TODO: check this!
  respond(Dict(Genie.Router.response_type() => msg), status_code, Dict{String,String}())
end
const error! = http_error


end
