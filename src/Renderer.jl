module Renderer

export respond, html, json, redirect

import Revise
import JSON, HTTP, Reexport, Markdown, Logging, FilePaths
import Genie, Genie.Util, Genie.Configuration, Genie.Exceptions

Reexport.@reexport using Genie.Flax

const JSONParser = JSON
const Html = Genie.Flax

export Html

const DEFAULT_CHARSET = "charset=utf-8"
const DEFAULT_CONTENT_TYPE = :html

"""
    const CONTENT_TYPES = Dict{Symbol,String}

Collection of content-types mappings between user friendly short names and
MIME types plus charset.
"""
const CONTENT_TYPES = Dict{Symbol,String}(
  :html       => "text/html; $DEFAULT_CHARSET",
  :plain      => "text/plain; $DEFAULT_CHARSET",
  :text       => "text/plain; $DEFAULT_CHARSET",
  :json       => "application/json; $DEFAULT_CHARSET",
  :js         => "application/javascript; $DEFAULT_CHARSET",
  :javascript => "application/javascript; $DEFAULT_CHARSET",
  :xml        => "text/xml; $DEFAULT_CHARSET",
  :markdown   => "text/markdown; $DEFAULT_CHARSET"
)

const ResourcePath = Union{String,Symbol}
const HTTPHeaders = Dict{String,String}

const FilePath = FilePaths.PosixPath
const filepath = FilePaths.Path
export FilePath, filepath

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

Represents an object that can be rendered on the web as a HTTP Response
"""
mutable struct WebRenderable
  body::String
  content_type::Symbol
  status::Int
  headers::HTTPHeaders
end


"""
    WebRenderable(body::String)

Creates a new instance of `WebRenderable` with `body` as the body of the response and
default content type, no headers, and 200 status code.

#Examples
```jldoctest
julia> Genie.Renderer.WebRenderable("hello")
Genie.Renderer.WebRenderable("hello", :html, 200, Dict{String,String}())
```
"""
WebRenderable(body::String) = WebRenderable(body, DEFAULT_CONTENT_TYPE, 200, HTTPHeaders())


"""
    WebRenderable(body::String, content_type::Symbol)

Creates a new instance of `WebRenderable` with `body` as the body of the response and
`content_type` as the content type, no headers, and 200 status code.

#Examples
```jldoctest
julia> Genie.Renderer.WebRenderable("hello", :json)
Genie.Renderer.WebRenderable("hello", :json, 200, Dict{String,String}())
```
"""
WebRenderable(body::String, content_type::Symbol) = WebRenderable(body, content_type, 200, HTTPHeaders())


"""
    WebRenderable(; body::String = "", content_type::Symbol = DEFAULT_CONTENT_TYPE,
                    status::Int = 200, headers::HTTPHeaders = HTTPHeaders())

Creates a new instance of `WebRenderable` using the values passed as keyword arguments.

#Examples
```jldoctest
julia> Genie.Renderer.WebRenderable()
Genie.Renderer.WebRenderable("", :html, 200, Dict{String,String}())

julia> Genie.Renderer.WebRenderable(body = "bye", content_type = :js, status = 301, headers = Dict("Location" => "/bye"))
Genie.Renderer.WebRenderable("bye", :js, 301, Dict("Location" => "/bye"))
```
"""
WebRenderable(; body::String = "", content_type::Symbol = DEFAULT_CONTENT_TYPE,
                status::Int = 200, headers::HTTPHeaders = HTTPHeaders()) = WebRenderable(body, content_type, status, headers)


"""
    WebRenderable(wr::WebRenderable, status::Int, headers::HTTPHeaders)

Returns `wr` overwriting its `status` and `headers` fields with the passed arguments.

#Examples
```jldoctest
julia> Genie.Renderer.WebRenderable(Genie.Renderer.WebRenderable(body = "good morning", content_type = :js), 302, Dict("Location" => "/morning"))
Genie.Renderer.WebRenderable("good morning", :js, 302, Dict("Location" => "/morning"))
```
"""
function WebRenderable(wr::WebRenderable, status::Int, headers::HTTPHeaders)
  wr.status = status
  wr.headers = headers

  wr
end


"""
"""
function tohtml(resource::ResourcePath, action::ResourcePath;
                  layout::ResourcePath = Genie.config.renderer_default_layout_file, context::Module = @__MODULE__, vars...) :: WebRenderable
  WebRenderable(Flax.HTMLRenderer.render(resource, action; layout = layout, context = context, vars...) |> Base.invokelatest)
end
function tohtml(data::String; context::Module = @__MODULE__, layout::Union{ResourcePath,Nothing} = nothing, vars...) :: WebRenderable
  WebRenderable(Flax.HTMLRenderer.render(data; context = context, layout = layout, vars...) |> Base.invokelatest)
end
function tohtml(restful_resource::WebResource; context::Module = @__MODULE__, vars...) :: WebRenderable
  WebRenderable(restful_resource.resource, restful_resource.action, layout = restful_resource.layout, context = context, vars...)
end
function tohtml(viewfile::FilePath; layout::Union{Nothing,FilePath} = nothing,
                  context::Module = @__MODULE__, vars...) :: WebRenderable
  WebRenderable(Flax.HTMLRenderer.render(viewfile; layout = layout, context = context, vars...) |> Base.invokelatest)
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


"""
    html(viewfile::FilePath; layout::Union{Nothing,FilePath} = nothing,
          context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), vars...) :: HTTP.Response


"""
function html(viewfile::FilePath; layout::Union{Nothing,FilePath} = nothing,
                context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), vars...) :: HTTP.Response
  WebRenderable(tohtml(viewfile; layout = layout, context = context, vars...), status, headers) |> respond
end

### JSON RENDERING ###

"""
Invokes the JSON renderer of the underlying configured templating library.
"""
function tojson(resource::ResourcePath, action::ResourcePath; context::Module = @__MODULE__, vars...) :: WebRenderable
  WebRenderable(Flax.JSONRenderer.render(resource, action; context = context, vars...) |> Base.invokelatest, :json)
end
function tojson(data::Any) :: WebRenderable
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

function respond(err::T, content_type::Union{Symbol,String} = Genie.Router.responsetype(), code::Int = 500) :: T where {T<:Exception}
  T
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