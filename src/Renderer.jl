module Renderer

export respond, redirect, render

import EzXML, FilePathsBase, HTTP, JuliaFormatter, Logging, Markdown, SHA, OrderedCollections
import Genie
using Genie.Context

const DEFAULT_CHARSET = "charset=utf-8"
const DEFAULT_CONTENT_TYPE = :html
const DEFAULT_LAYOUT_FILE = "app"

const VIEWS_FOLDER = "views"

const BUILD_NAME = "GenieViews"

"""
    const CONTENT_TYPES = Dict{Symbol,String}

Collection of content-types mappings between user friendly short names and
MIME types plus charset.
"""
const CONTENT_TYPES = OrderedCollections.LittleDict{Symbol,String}(
  :html       => "text/html; $DEFAULT_CHARSET",
  :text       => "text/plain; $DEFAULT_CHARSET",
  :json       => "application/json; $DEFAULT_CHARSET",
  :javascript => "application/javascript; $DEFAULT_CHARSET",
  :xml        => "text/xml; $DEFAULT_CHARSET",
  :markdown   => "text/markdown; $DEFAULT_CHARSET",
  :css        => "text/css; $DEFAULT_CHARSET",
  :fontwoff2  => "font/woff2",
  :favicon    => "image/x-icon",
  :png        => "image/png",
  :jpg        => "image/jpeg",
  :svg        => "image/svg+xml"
)

const MIME_TYPES = OrderedCollections.LittleDict(
  :html       => MIME"text/html",
  :text       => MIME"text/plain",
  :json       => MIME"application/json",
  :javascript => MIME"application/javascript",
  :xml        => MIME"text/xml",
  :markdown   => MIME"text/markdown",
  :css        => MIME"text/css",
  :fontwoff2  => MIME"font/woff2",
)

const MAX_FILENAME_LENGTH = 1_000

push_content_type(s::Symbol, content_type::String, charset::String = DEFAULT_CHARSET) = (CONTENT_TYPES[s] = "$content_type; $charset")

const ResourcePath = Union{String,Symbol}
const HTTPHeaders = OrderedCollections.LittleDict

const Path = FilePathsBase.Path
const FilePath = Union{FilePathsBase.PosixPath,FilePathsBase.WindowsPath}
const filepath = FilePathsBase.Path

macro path_str(s)
  :(FilePathsBase.@p_str($s))
end

export FilePath, filepath, Path, @path_str
export vars
export WebRenderable


init_task_local_storage() = (haskey(task_local_storage(), :__vars) || task_local_storage(:__vars, Dict{Symbol,Any}()))
init_task_local_storage()
clear_task_storage() = task_local_storage(:__vars, Dict{Symbol,Any}())

response_status(params::Params, status::Int) = params[:response].status != 0 ? convert(Int, params[:response].status) : status
response_content_type(params::Params, content_type = DEFAULT_CONTENT_TYPE) = content_type != DEFAULT_CONTENT_TYPE ? content_type : get(params, :response_type, DEFAULT_CONTENT_TYPE)

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
function WebRenderable(body::String, content_type::Symbol, status::Int, headers::HTTPHeaders, params::Params)
  status = response_status(params, status)
  content_type = response_content_type(params, content_type)
  headers = merge(params[:response].headers |> Dict, headers)

  WebRenderable(body, content_type, status, headers)
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
WebRenderable(body::String, params::Params = Params()) = WebRenderable(body, response_content_type(params), response_status(params, 200), HTTPHeaders(), params)


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
WebRenderable(body::String, content_type::Symbol, params::Params = Params()) = WebRenderable(body, content_type, response_status(params, 200), HTTPHeaders(), params)


"""
    WebRenderable(; body::String = "", content_type::Symbol = DEFAULT_CONTENT_TYPE,
                    status::Int = 200, headers::HTTPHeaders = HTTPHeaders())

Creates a new instance of `WebRenderable` using the values passed as keyword arguments.

#Examples
```jldoctest
julia> Genie.Renderer.WebRenderable()
Genie.Renderer.WebRenderable("", :html, 200, Dict{String,String}())

julia> Genie.Renderer.WebRenderable(body = "bye", content_type = :javascript, status = 301, headers = Dict("Location" => "/bye"))
Genie.Renderer.WebRenderable("bye", :javascript, 301, Dict("Location" => "/bye"))
```
"""
WebRenderable(; body::String = "",
                status::Int = 200,
                headers::HTTPHeaders = HTTPHeaders(),
                params::Params = Params(),
                content_type::Symbol = response_content_type(params),
                kwargs...) = begin
                  WebRenderable(body, content_type, status, headers, params)
                end


"""
    WebRenderable(wr::WebRenderable, status::Int, headers::HTTPHeaders)

Returns `wr` overwriting its `status` and `headers` fields with the passed arguments.

#Examples
```jldoctest
julia> Genie.Renderer.WebRenderable(Genie.Renderer.WebRenderable(body = "good morning", content_type = :javascript), 302, Dict("Location" => "/morning"))
Genie.Renderer.WebRenderable("good morning", :javascript, 302, Dict("Location" => "/morning"))
```
"""
function WebRenderable(wr::WebRenderable, status::Int, headers::HTTPHeaders, params::Params = Params())
  wr.status = status
  wr.headers = merge(params[:response].headers |> Dict, headers)

  WebRenderable(wr.body, wr.content_type, wr.status, wr.headers, params)
end


function WebRenderable(wr::WebRenderable, content_type::Symbol, status::Int, headers::HTTPHeaders, params::Params = Params())
  wr.content_type = content_type
  wr.status = status
  wr.headers = merge(params[:response].headers |> Dict, headers)

  WebRenderable(wr.body, wr.content_type, wr.status, wr.headers, params)
end


function WebRenderable(f::Function, args...)
  fr::String = Base.invokelatest(f) |> join

  WebRenderable(fr, args...)
end


"""
    render

Abstract function that needs to be specialized by individual renderers.
"""
function render end


### REDIRECT RESPONSES ###

"""
Sets redirect headers and prepares the `Response`.
It accepts 3 parameters:
1 - Label of a Route (to learn more, see the advanced routes section)
2 - Default HTTP 302 Found Status: indicates that the provided resource will be changed to a URL provided
3 - Tuples (key, value) to define the HTTP request header

Example:
julia> Genie.Renderer.redirect(:index, 302, Dict("Content-Type" => "application/json; charset=UTF-8"))

HTTP.Messages.Response:
HTTP/1.1 302 Moved Temporarily
Content-Type: application/json; charset=UTF-8
Location: /index

Redirecting you to /index

"""
function redirect(location::String, code::Int = 302, headers::HTTPHeaders = HTTPHeaders()) :: HTTP.Response
  headers["Location"] = location
  WebRenderable("Redirecting you to $location", :html, code, headers) |> respond
end
@noinline function redirect(named_route::Symbol, code::Int = 302, headers::HTTPHeaders = HTTPHeaders(); route_args...) :: HTTP.Response
  redirect(Genie.Router.to_url(named_route; route_args...), code, headers)
end


### RESPONSES ###


"""
Constructs a `Response` corresponding to the Content-Type of the request.
"""
function respond(r::WebRenderable) :: HTTP.Response
  haskey(r.headers, "Content-Type") || (r.headers["Content-Type"] = CONTENT_TYPES[r.content_type])

  HTTP.Response(r.status, [h for h in r.headers], body = r.body)
end


function respond(response::HTTP.Response) :: HTTP.Response
  response
end


function respond(body::String, params::Dict{Symbol,T})::HTTP.Response where {T}
  r = params[:response]
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


"""
    registervars(vs...) :: Nothing

Loads the rendering vars into the task's scope
"""
function registervars(; context::Module = @__MODULE__, vs...) :: Nothing
  task_local_storage(:__vars, merge(vars(), Dict{Symbol,Any}(vs), Dict{Symbol,Any}(:context => context)))

  nothing
end


"""
    injectkwvars() :: String

Sets up variables passed into the view, making them available in the
generated view function as kw arguments for the rendering function.
"""
function injectkwvars() :: String
  output = String[]

  for kv in vars()
    push!(output, "$(kv[1]) = Genie.Renderer.vars($(repr(kv[1])))")
  end

  join(output, ',')
end


"""
    view_file_info(path::String, supported_extensions::Vector{String}) :: Tuple{String,String}

Extracts path and extension info about a file
"""
function view_file_info(path::String, supported_extensions::Vector{String}) :: Tuple{String,String}
  _path, _extension = "", ""

  if isfile(path)
    _path_without_extension, _extension = Base.Filesystem.splitext(path)
    _path = _path_without_extension * _extension
  else
    for file_extension in supported_extensions
      if isfile(path * file_extension)
        _path, _extension = path * file_extension, file_extension
        break
      end
    end
  end

  if ! isfile(_path)
    error_message = length(supported_extensions) == 1 ?
                      """Template file "$path$(supported_extensions[1])" does not exist""" :
                      """Template file "$path" with extensions $supported_extensions does not exist"""
    throw(Genie.Exceptions.ExceptionalResponse(error_message))
  end

  return _path, _extension
end


"""
    vars_signature() :: String

Collects the names of the view vars in order to create a unique hash/salt to identify
compiled views with different vars.
"""
function vars_signature() :: String
  vars() |> keys |> collect |> sort |> string
end


"""
    function_name(file_path::String)

Generates function name for generated HTML+Julia views.
"""
function function_name(file_path::String) :: String
  "func_$(SHA.sha1( relpath(isempty(file_path) ? " " : file_path) * vars_signature() ) |> bytes2hex)"
end


"""
    m_name(file_path::String)

Generates module name for generated HTML+Julia views.
"""
function m_name(file_path::String) :: String
  string(SHA.sha1( relpath(isempty(file_path) ? " " : file_path) * vars_signature()) |> bytes2hex)
end


"""
    build_is_stale(file_path::String, build_path::String) :: Bool

Checks if the view template has been changed since the last time the template was compiled.
"""
function build_is_stale(file_path::String, build_path::String) :: Bool
  isfile(file_path) || return true

  file_mtime = stat(file_path).mtime
  build_mtime = stat(build_path).mtime
  status = file_mtime > build_mtime

  status
end


"""
    build_module(content::String, path::String, mod_name::String) :: String

Persists compiled Julia view data to file and returns the path
"""
function build_module(content::S, path::T, mod_name::U; output_path::Bool = true)::String where {S<:AbstractString,T<:AbstractString,U<:AbstractString}
  module_path = joinpath(Genie.config.path_build, BUILD_NAME, mod_name)

  isdir(dirname(module_path)) || mkpath(dirname(module_path))

  open(module_path, "w") do io
    output_path && write(io, "# $path \n\n")
    write(io,
      Genie.config.format_julia_builds ?
      (try
        JuliaFormatter.format_text(content)
      catch ex
        @error ex
        content
      end) : content)
  end

  module_path
end


"""
    preparebuilds() :: Bool

Sets up the build folder and the build module file for generating the compiled views.
"""
function preparebuilds(subfolder = BUILD_NAME) :: Bool
  build_path = joinpath(Genie.config.path_build, subfolder)
  isdir(build_path) || mkpath(build_path)

  true
end


"""
    purgebuilds(subfolder = BUILD_NAME) :: Bool

Removes the views builds folders with all the generated views.
"""
function purgebuilds(subfolder = BUILD_NAME) :: Bool
  rm(joinpath(Genie.config.path_build, subfolder), force = true, recursive = true)

  true
end


"""
    changebuilds(subfolder = BUILD_NAME) :: Bool

Changes/creates a new builds folder.
"""
function changebuilds(subfolder = BUILD_NAME) :: Bool
  Genie.config.path_build = Genie.Configuration.buildpath()
  preparebuilds()
end


"""
    function vars

Utility for accessing view vars
"""
function vars()
  haskey(task_local_storage(), :__vars) ? task_local_storage(:__vars) : init_task_local_storage()
end


"""
    function vars(key)

Utility for accessing view vars stored under `key`
"""
function vars(key)
  vars()[key]
end


"""
    function vars(key, value)

Utility for setting a new view var, as `key` => `value`
"""
function vars(key, value)
  if haskey(task_local_storage(), :__vars)
    vars()[key] = value
  else
    task_local_storage(:__vars, Dict(key => value))
  end
end


"""
    set_negotiated_content(req::HTTP.Request, res::HTTP.Response, params::Dict{Symbol,Any})

Configures the request, response, and params response content type based on the request and defaults.
"""
function set_negotiated_content(req::HTTP.Request, res::HTTP.Response, params::Genie.Context.Params) :: Tuple{HTTP.Request,HTTP.Response,Genie.Context.Params}
  req_type = Genie.Router.request_type(req)

  params.collection[:response_type] = req_type
  params.collection[:mime] = get!(MIME_TYPES, req_type, typeof(MIME(req_type)))

  push!(res.headers, "Content-Type" => get!(CONTENT_TYPES, params[:response_type], string(MIME(req_type))))

  req, res, params
end


"""
    negotiate_content(req::Request, res::Response, params::Params) :: Response

Computes the content-type of the `Response`, based on the information in the `Request`.
"""
function negotiate_content(req::HTTP.Request, res::HTTP.Response, params::Params) :: Tuple{HTTP.Request,HTTP.Response,Params}
  headers = OrderedCollections.LittleDict(res.headers)

  if haskey(params, :response_type) && in(Symbol(params[:response_type]), collect(keys(CONTENT_TYPES)) )
    params.collection[:response_type] = Symbol(params[:response_type])
    params.collection[:mime] = MIME_TYPES[Symbol(params[:response_type])]

    headers["Content-Type"] = CONTENT_TYPES[params[:response_type]]

    res.headers = [k for k in headers]

    return req, res, params
  end

  negotiation_header = haskey(headers, "Accept") ? "Accept" :
                        ( haskey(headers, "Content-Type") ? "Content-Type" : "" )

  if isempty(negotiation_header)
    req, res, params = set_negotiated_content(req, res, params)

    return req, res, params
  end

  accept_parts = split(headers[negotiation_header], ";")

  if isempty(accept_parts)
    req, res, params = set_negotiated_content(req, res, params)

    return req, res, params
  end

  accept_order_parts = split(accept_parts[1], ",")

  if isempty(accept_order_parts)
    req, res, params = set_negotiated_content(req, res, params)

    return req, res, params
  end

  for mime in accept_order_parts
    if occursin('/', mime)
      content_type = split(mime, '/')[2] |> lowercase |> Symbol
      if haskey(CONTENT_TYPES, content_type)
        params.collection[:response_type] = content_type
        params.collection[:mime] = MIME_TYPES[content_type]

        headers["Content-Type"] = CONTENT_TYPES[params[:response_type]]

        res.headers = [k for k in headers]

        return req, res, params
      end
    end
  end

  req, res, params = set_negotiated_content(req, res, params)

  return req, res, params
end

push!(Genie.Router.content_negotiation_hooks, negotiate_content)


include("renderers/Html.jl")
include("renderers/Json.jl")
include("renderers/Js.jl")

end

const Renderers = Renderer