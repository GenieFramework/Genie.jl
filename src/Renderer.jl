module Renderer

export respond, html, json, redirect

import Revise
import HTTP, Reexport, Markdown, Logging, FilePaths
import Genie, Genie.Util, Genie.Configuration, Genie.Exceptions

Reexport.@reexport using Genie.Flax

const Html = Genie.Flax
export Html

const DEFAULT_CHARSET = "charset=utf-8"
const DEFAULT_CONTENT_TYPE = :html
const DEFAULT_LAYOUT_FILE = "app"

const VIEWS_FOLDER = "views"
const LAYOUTS_FOLDER = "layouts"

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

"""
    const RENDERERS = Dict

Collection of renderers associated to each supported mime time. Other mime-renderer pairs can be added -
or current ones can be replaced by custom ones, to be used by Genie.
"""
const RENDERERS = Dict(
  MIME"text/html"         => Flax.HTMLRenderer,
  MIME"application/json"  => Flax.JSONRenderer
)

const ResourcePath = Union{String,Symbol}
const HTTPHeaders = Dict{String,String}

const FilePath = FilePaths.PosixPath
const filepath = FilePaths.Path
export FilePath, filepath


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


function render(::Type{MIME"text/html"}, data::String;
                context::Module = @__MODULE__, layout::Union{String,Nothing} = nothing, vars...) :: WebRenderable
  WebRenderable(RENDERERS[MIME"text/html"].render(data; context = context, layout = layout, vars...) |> Base.invokelatest)
end
function render(::Type{MIME"text/html"}, viewfile::FilePath; layout::Union{Nothing,FilePath} = nothing,
                  context::Module = @__MODULE__, vars...) :: WebRenderable
  WebRenderable(RENDERERS[MIME"text/html"].render(viewfile; layout = layout, context = context, vars...) |> Base.invokelatest)
end


"""
"""
function html(resource::ResourcePath, action::ResourcePath; layout::ResourcePath = DEFAULT_LAYOUT_FILE,
                context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), vars...) :: HTTP.Response
  html(FilePaths.Path(joinpath(Genie.config.path_resources, string(resource), VIEWS_FOLDER, string(action)));
        layout = FilePaths.Path(joinpath(Genie.config.path_app, LAYOUTS_FOLDER, string(layout))),
        context = context, status = status, headers = headers, vars...)
end


"""
    html(data::String; context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), layout::Union{String,Nothing} = nothing, vars...) :: HTTP.Response

Parses the `data` input as HTML, returning a HTML HTTP Response.

# Arguments
- `data::String`: the HTML string to be rendered
- `context::Module`: the module in which the variables are evaluated (in order to provide the scope for vars). Usually the controller.
- `status::Int`: status code of the response
- `headers::HTTPHeaders`: HTTP response headers
- `layout::Union{String,Nothing}`: layout file for rendering `data`

# Example
```jldoctest
julia> html("<h1>Welcome \$(@vars(:name))</h1>", layout = "<div><% @yield %></div>", name = "Adrian")
HTTP.Messages.Response:
"
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8

<html><head></head><body><div><h1>Welcome Adrian</h1>
</div></body></html>"
```
"""
function html(data::String; context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), layout::Union{String,Nothing} = nothing, vars...) :: HTTP.Response
  WebRenderable(render(MIME"text/html", data; context = context, layout = layout, vars...), status, headers) |> respond
end


"""
    html(viewfile::FilePath; layout::Union{Nothing,FilePath} = nothing,
          context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), vars...) :: HTTP.Response

Parses and renders the HTML `viewfile`, optionally rendering it within the `layout` file. Valid file formats are `.html.jl` and `.flax.jl`.

# Arguments
- `viewfile::FilePath`: filesystem path to the view file as a `Renderer.FilePath`, ie `Renderer.FilePath("/path/to/file.html.jl")`
- `layout::FilePath`: filesystem path to the layout file as a `Renderer.FilePath`, ie `Renderer.FilePath("/path/to/file.html.jl")`
- `context::Module`: the module in which the variables are evaluated (in order to provide the scope for vars). Usually the controller.
- `status::Int`: status code of the response
- `headers::HTTPHeaders`: HTTP response headers
"""
function html(viewfile::FilePath; layout::Union{Nothing,FilePath} = nothing,
                context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), vars...) :: HTTP.Response
  WebRenderable(render(MIME"text/html", viewfile; layout = layout, context = context, vars...), status, headers) |> respond
end



### JSON RENDERING ###


function render(::Type{MIME"application/json"}, datafile::FilePath; context::Module = @__MODULE__, vars...) :: WebRenderable
  WebRenderable(RENDERERS[MIME"application/json"].render(datafile; context = context, vars...) |> Base.invokelatest, :json)
end
function render(::Type{MIME"application/json"}, data::String; context::Module = @__MODULE__, vars...) :: WebRenderable
  WebRenderable(RENDERERS[MIME"application/json"].render(data; context = context, vars...) |> Base.invokelatest, :json)
end
function render(::Type{MIME"application/json"}, data::Any) :: WebRenderable
  WebRenderable(RENDERERS[MIME"application/json"].render(data) |> Base.invokelatest, :json)
end


"""
"""
function json(resource::ResourcePath, action::ResourcePath; context::Module = @__MODULE__,
              status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), vars...) :: HTTP.Response
  json(FilePaths.Path(joinpath(Genie.config.path_resources, string(resource), VIEWS_FOLDER, string(action) * RENDERERS[MIME"application/json"].JSON_FILE_EXT));
        context = context, status = status, headers = headers, vars...)
end


"""
"""
function json(datafile::FilePath; context::Module = @__MODULE__,
              status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), vars...) :: HTTP.Response
  WebRenderable(render(MIME"application/json", datafile; context = context, vars...), status, headers) |> respond
end


"""
"""
function json(data::String; context::Module = @__MODULE__,
              status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), vars...) :: HTTP.Response
  WebRenderable(render(MIME"application/json", data; context = context, vars...), status, headers) |> respond
end


"""
"""
function json(data; status::Int = 200, headers::HTTPHeaders = HTTPHeaders()) :: HTTP.Response
  WebRenderable(render(MIME"application/json", data), status, headers) |> respond
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