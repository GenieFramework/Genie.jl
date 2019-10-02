module Renderer

export respond, html, json, redirect

using Nullables, JSON, HTTP, Reexport, Markdown, Logging
using Genie, Genie.Util, Genie.Configuration, Genie.Exceptions

@reexport using Genie.Flax

const default_charset = "charset=utf-8"

const CONTENT_TYPES = Dict{Symbol,String}(
  :html       => "text/html; $default_charset",
  :plain      => "text/plain; $default_charset",
  :text       => "text/plain; $default_charset",
  :json       => "application/json; $default_charset",
  :js         => "application/javascript; $default_charset",
  :javascript => "application/javascript; $default_charset",
  :xml        => "text/xml; $default_charset",
  :markdown   => "text/markdown; $default_charset"
)
const DEFAULT_CONTENT_TYPE = :html
const ResourcePath = Union{String,Symbol}
const HTTPHeaders = Dict{String,String}

const JSONParser = JSON
const Html = Flax

"""
    mutable struct WebResource

Represents a resource that can be resolved by the view layer
"""
mutable struct WebResource
  resource::ResourcePath
  action::ResourcePath
  layout::ResourcePath
end


"""
    mutable struct WebRenderable

Represents an object that can be rendered on the web
"""
mutable struct WebRenderable
  body::String
  content_type::Symbol
  status::Int
  headers::HTTPHeaders
end


WebRenderable(body::String) = WebRenderable(body, DEFAULT_CONTENT_TYPE, 200, HTTPHeaders())
WebRenderable(body::String, content_type::Symbol) = WebRenderable(body, content_type, 200, HTTPHeaders())
WebRenderable(; body::String = "", content_type::Symbol = DEFAULT_CONTENT_TYPE,
                status::Int = 200, headers::HTTPHeaders = HTTPHeaders()) = WebRenderable(body, content_type, status, headers)
function WebRenderable(wr::WebRenderable, status::Int, headers::HTTPHeaders)
  wr.status = status
  wr.headers = headers

  wr
end


"""
"""
function tohtml(resource::ResourcePath, action::ResourcePath;
                  layout::ResourcePath = Genie.config.renderer_default_layout_file, context::Module = @__MODULE__, vars...) :: WebRenderable
  WebRenderable(Flax.html_renderer(resource, action; layout = layout, context = context, vars...) |> Base.invokelatest)
end
function tohtml(data::String; context::Module = @__MODULE__, layout::Union{ResourcePath,Nothing} = nothing, vars...) :: WebRenderable
  WebRenderable(Flax.html_renderer(data; context = context, layout = layout, vars...) |> Base.invokelatest)
end
function tohtml(restful_resource::WebResource; context::Module = @__MODULE__, vars...) :: WebRenderable
  WebRenderable(restful_resource.resource, restful_resource.action, layout = restful_resource.layout, context = context, vars...)
end


"""
"""
function html(resource::ResourcePath, action::ResourcePath; layout::ResourcePath = Genie.config.renderer_default_layout_file,
                context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), vars...) :: HTTP.Response
  WebRenderable(tohtml(resource, action; layout = layout, context = context, vars...), status, headers) |> respond
end
function html(data::String; context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), layout::Union{ResourcePath,Nothing} = nothing, vars...) :: HTTP.Response
  WebRenderable(tohtml(data; context = context, layout = layout, vars...), status, headers) |> respond
end
function html(data::HTML; context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), layout::Union{ResourcePath,Nothing} = nothing, vars...) :: HTTP.Response
  html(data.content, context = context, status = status, headers = headers, layout = layout, vars...)
end

### JSON RENDERING ###

"""
Invokes the JSON renderer of the underlying configured templating library.
"""
function tojson(resource::ResourcePath, action::ResourcePath; context::Module = @__MODULE__, vars...) :: WebRenderable
  WebRenderable(Flax.json_renderer(resource, action; context = context, vars...) |> Base.invokelatest, :json)
end
function tojson(data) :: WebRenderable
  WebRenderable(JSONParser.json(data), :json)
end


"""
"""
function json(resource::ResourcePath, action::ResourcePath; context::Module = @__MODULE__,
              status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), vars...) :: HTTP.Response
  WebRenderable(tojson(resource, action; context = context, vars...), status, headers) |> respond
end
function json(data; status::Int = 200, headers::HTTPHeaders = HTTPHeaders()) :: HTTP.Response
  WebRenderable(tojson(data), status, headers) |> respond
end

### REDIRECT RESPONSES ###

"""
Sets redirect headers and prepares the `Response`.
"""
function redirect(location::String, code::Int = 302, headers::HTTPHeaders = HTTPHeaders()) :: HTTP.Response
  headers["Location"] = location
  WebRenderable("Redirecting you to $location", :text, code, headers) |> respond
end
function redirect(named_route::Symbol, code::Int = 302, headers::HTTPHeaders = HTTPHeaders(); route_args...) :: HTTP.Response
  redirect(Genie.Router.linkto(named_route; route_args...), code, headers)
end


"""
    hasrequested(content_type::Symbol) :: Bool

Checks wheter or not the requested content type matches `content_type`.
"""
function hasrequested(content_type::Symbol) :: Bool
  task_local_storage(:__params)[:response_type] == content_type
end

### RESPONSES ###

"""
Constructs a `Response` corresponding to the content-type sof the request.
"""
function respond(r::WebRenderable) :: HTTP.Response
  haskey(r.headers, "Content-Type") || (r.headers["Content-Type"] = CONTENT_TYPES[r.content_type])

  HTTP.Response(r.status, [h for h in r.headers], body = r.body)
end
function respond(response::HTTP.Response) :: HTTP.Response
  response
end
function respond(body::String, params::Dict{Symbol,T})::HTTP.Response where {T}
  r = params[:RESPONSE]
  r.data = body

  r |> respond
end
function respond(err::T, content_type::Union{Symbol,String} = Genie.Router.responsetype(), code::Int = 500)::HTTP.Response where {T<:Exception}
  HTTP.Response(code, (isa(content_type, Symbol) ? ["Content-Type" => CONTENT_TYPES[content_type]] : ["Content-Type" => content_type]), body = string(err))  |> ExceptionalResponse
end
function respond(body::String, content_type::Union{Symbol,String} = Genie.Router.responsetype(), code::Int = 200) :: HTTP.Response
  HTTP.Response(code,
                (isa(content_type, Symbol) ? ["Content-Type" => CONTENT_TYPES[content_type]] : ["Content-Type" => content_type]),
                body = body)
end
function respond(body, code::Int = 200, headers::HTTPHeaders = HTTPHeaders())
  HTTP.Response(code, [h for h in headers], body = string(body))
end
function respond(f::Function, code::Int = 200, headers::HTTPHeaders = HTTPHeaders())
  respond(f(), code, headers)
end


end