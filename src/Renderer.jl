module Renderer

export respond, redirect, render

import Revise
import HTTP, Markdown, Logging, FilePaths, SHA
import Genie

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
const CONTENT_TYPES = Dict{Symbol,String}(
  :html       => "text/html; $DEFAULT_CHARSET",
  :text       => "text/plain; $DEFAULT_CHARSET",
  :json       => "application/json; $DEFAULT_CHARSET",
  :javascript => "application/javascript; $DEFAULT_CHARSET",
  :xml        => "text/xml; $DEFAULT_CHARSET",
  :markdown   => "text/markdown; $DEFAULT_CHARSET",
  :favicon    => "image/x-icon",
  :css        => "text/css; $DEFAULT_CHARSET",
)

const MIME_TYPES = Dict(
  :html       => MIME"text/html",
  :text       => MIME"text/plain",
  :json       => MIME"application/json",
  :javascript => MIME"application/javascript",
  :xml        => MIME"text/xml",
  :markdown   => MIME"text/markdown",
  :css        => MIME"text/css"
)

push_content_type(s::Symbol, content_type::String, charset::String = DEFAULT_CHARSET) = (CONTENT_TYPES[s] = "$content_type; $charset")

const ResourcePath = Union{String,Symbol}
const HTTPHeaders = Dict{String,String}

const Path = FilePaths.Path
const FilePath = Union{FilePaths.PosixPath,FilePaths.WindowsPath}
const filepath = FilePaths.Path

macro path_str(s)
  :(FilePaths.@p_str($s))
end

export FilePath, filepath, Path, @path_str
export @vars
export WebRenderable

init_task_local_storage() = (haskey(task_local_storage(), :__vars) || task_local_storage(:__vars, Dict{Symbol,Any}()))
init_task_local_storage()
clear_task_storage() = task_local_storage(:__vars, Dict{Symbol,Any}())


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

julia> Genie.Renderer.WebRenderable(body = "bye", content_type = :javascript, status = 301, headers = Dict("Location" => "/bye"))
Genie.Renderer.WebRenderable("bye", :javascript, 301, Dict("Location" => "/bye"))
```
"""
WebRenderable(; body::String = "", content_type::Symbol = DEFAULT_CONTENT_TYPE,
                status::Int = 200, headers::HTTPHeaders = HTTPHeaders()) = WebRenderable(body, content_type, status, headers)


"""
    WebRenderable(wr::WebRenderable, status::Int, headers::HTTPHeaders)

Returns `wr` overwriting its `status` and `headers` fields with the passed arguments.

#Examples
```jldoctest
julia> Genie.Renderer.WebRenderable(Genie.Renderer.WebRenderable(body = "good morning", content_type = :javascript), 302, Dict("Location" => "/morning"))
Genie.Renderer.WebRenderable("good morning", :javascript, 302, Dict("Location" => "/morning"))
```
"""
function WebRenderable(wr::WebRenderable, status::Int, headers::HTTPHeaders)
  wr.status = status
  wr.headers = headers

  wr
end


function WebRenderable(wr::WebRenderable, content_type::Symbol, status::Int, headers::HTTPHeaders)
  wr.content_type = content_type
  wr.status = status
  wr.headers = headers

  wr
end


function WebRenderable(f::Function, args...)
  fr::String = try
    f()::String
  catch
    Base.invokelatest(f)::String
  end

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


"""
    registervars(vars...) :: Nothing

Loads the rendering vars into the task's scope
"""
function registervars(vars...) :: Nothing
  init_task_local_storage()
  task_local_storage(:__vars, merge(task_local_storage(:__vars), Dict{Symbol,Any}(vars)))

  nothing
end


"""
    injectvars() :: String

Sets up variables passed into the view, making them available in the
generated view function.
"""
function injectvars() :: String
  output = ""
  for kv in task_local_storage(:__vars)
    output *= "$(kv[1]) = try \n"
    output *= "$(kv[1]) = Genie.Renderer.@vars($(repr(kv[1]))) \n"
    output *= "
catch ex
  @error ex
end
"
  end

  output
end


function injectvars(context::Module) :: Nothing
  for kv in task_local_storage(:__vars)
    Core.eval(context, Meta.parse("$(kv[1]) = Renderer.@vars($(repr(kv[1])))"))
  end

  nothing
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

  return _path, _extension
end


"""
    vars_signature() :: String

Collects the names of the view vars in order to create a unique hash/salt to identify
compiled views with different vars.
"""
function vars_signature() :: String
  task_local_storage(:__vars) |> keys |> collect |> sort |> string
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
function build_module(content::String, path::String, mod_name::String) :: String
  module_path = joinpath(Genie.config.path_build, BUILD_NAME, mod_name)

  isdir(dirname(module_path)) || mkpath(dirname(module_path))

  open(module_path, "w") do io
    write(io, "# $path \n\n")
    write(io, content)
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
    @vars

Utility macro for accessing view vars
"""
macro vars()
  :(task_local_storage(:__vars))
end


"""
    @vars(key)

Utility macro for accessing view vars stored under `key`
"""
macro vars(key)
  :(task_local_storage(:__vars)[$key])
end


"""
    @vars(key, value)

Utility macro for setting a new view var, as `key` => `value`
"""
macro vars(key, value)
  quote
    try
      task_local_storage(:__vars)[$key] = $(esc(value))
    catch
      init_task_local_storage()
      task_local_storage(:__vars)[$key] = $(esc(value))
    end
  end
end


"""
    set_negotiated_content(req::HTTP.Request, res::HTTP.Response, params::Dict{Symbol,Any})

Configures the request, response, and params response content type based on the request and defaults.
"""
function set_negotiated_content(req::HTTP.Request, res::HTTP.Response, params::Dict{Symbol,Any})
  req_type = Genie.Router.request_type(req)
  params[:response_type] = req_type === nothing ? DEFAULT_CONTENT_TYPE : req_type
  params[Genie.PARAMS_MIME_KEY] = get(MIME_TYPES, params[:response_type], MIME_TYPES[DEFAULT_CONTENT_TYPE])
  push!(res.headers, "Content-Type" => get(CONTENT_TYPES, params[:response_type], "text/html"))

  req, res, params
end


"""
    negotiate_content(req::Request, res::Response, params::Params) :: Response

Computes the content-type of the `Response`, based on the information in the `Request`.
"""
function negotiate_content(req::HTTP.Request, res::HTTP.Response, params::Dict{Symbol,Any}) :: Tuple{HTTP.Request,HTTP.Response,Dict{Symbol,Any}}
  headers = Dict(res.headers)

  if haskey(params, :response_type) && in(Symbol(params[:response_type]), collect(keys(CONTENT_TYPES)) )
    params[:response_type] = Symbol(params[:response_type])
    params[Genie.PARAMS_MIME_KEY] = MIME_TYPES[params[:response_type]]
    headers["Content-Type"] = CONTENT_TYPES[params[:response_type]]

    res.headers = [k for k in headers]

    return req,res,params
  end

  negotiation_header = haskey(headers, "Accept") ? "Accept" : ( haskey(headers, "Content-Type") ? "Content-Type" : "" )

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
    if occursin("/", mime)
      content_type = split(mime, "/")[2] |> lowercase |> Symbol
      if haskey(CONTENT_TYPES, content_type)
        params[:response_type] = content_type
        params[Genie.PARAMS_MIME_KEY] = MIME_TYPES[params[:response_type]]
        headers["Content-Type"] = CONTENT_TYPES[params[:response_type]]

        res.headers = [k for k in headers]
        return req,res,params
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
