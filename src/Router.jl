module Router

using Revise
using Reexport, Logging
using HTTP, URIParser, HttpCommon, Nullables, Sockets, Millboard, Dates, OrderedCollections
using Genie, Genie.HTTPUtils, Genie.Sessions, Genie.Configuration, Genie.Input, Genie.Util, Genie.Renderer, Genie.Exceptions

include("mimetypes.jl")

export route, routes, channel, channels, serve_static_file
export GET, POST, PUT, PATCH, DELETE, OPTIONS
export tolink, linkto, responsetype, toroute
export error_404, error_500, error_xxx, err
export @params, @routes, @channels

@reexport using HttpCommon

const GET     = "GET"
const POST    = "POST"
const PUT     = "PUT"
const PATCH   = "PATCH"
const DELETE  = "DELETE"
const OPTIONS = "OPTIONS"

const BEFORE_HOOK  = :before
const AFTER_HOOK   = :after

const sessionless = Symbol[:json]

const request_mappings = Dict(
  :text       => "text/plain",
  :html       => "text/html",
  :json       => "application/json",
  :js         => "application/javascript",
  :javascript => "application/javascript",
  :form       => "application/x-www-form-urlencoded",
  :multipart  => "multipart/form-data",
  :file       => "application/octet-stream"
)


"""
    mutable struct Route

Representation of a route object
"""
mutable struct Route
  method::String
  path::String
  action::Function
  name::Union{Symbol,Nothing}

  Route(; method = GET, path = "", action = (() -> error("Route not set")), name = nothing) =
    new(method, path, action, name)
end


"""
    mutable struct Channel

Representation of a WebSocket Channel object
"""
mutable struct Channel
  path::String
  action::Function
  name::Union{Symbol,Nothing}

  Channel(; path = "", action = (() -> error("Channel not set")), name = nothing) =
    new(path, action)
end


function Base.show(io::IO, r::Route)
  print(io, "[$(r.method)] $(r.path) => $(r.action) | :$(r.name)")
end
function Base.show(io::IO, c::Channel)
  print(io, "[WS] $(c.path) => $(c.action) | :$(c.name)")
end


const _routes = OrderedDict{Symbol,Route}()
const _channels = OrderedDict{Symbol,Channel}()


"""
    mutable struct Params{T}

Collection of key value pairs representing the parameters of the current request - response cycle.
"""
mutable struct Params{T}
  collection::Dict{Symbol,T}
end
Params() = Params(Dict{Symbol,Any}())

Base.Dict(params::Params) = params.collection

Base.getindex(params, keys...) = getindex(Dict(params), keys...)


"""
    ispayload(req::HTTP.Request)

True if the request can carry a payload - that is, it's a `POST`, `PUT`, or `PATCH` request
"""
ispayload(req::HTTP.Request) = req.method in [POST, PUT, PATCH]


"""
    route_request(req::Request, res::Response, ip::IPv4 = Genie.config.server_host) :: Response

First step in handling a request: sets up @params collection, handles query vars, negotiates content, starts and persists sessions.
"""
function route_request(req::HTTP.Request, res::HTTP.Response, ip::IPv4 = IPv4(Genie.config.server_host)) :: HTTP.Response
  params = Params()
  params.collection[:request_ipv4] = ip

  res = negotiate_content(req, res, params)

  if is_static_file(req.target)
    Genie.config.server_handle_static_files && return serve_static_file(req.target)

    return error_404(req.target, req)
  end

  Revise.revise()

  session, res = Genie.config.session_auto_start ? Sessions.start(req, res) : (nothing, res)

  try
    res = match_routes(req, res, session, params)
  catch ex
    @error sprint(showerror, ex)
    @error "$(req.target) 500\n"

    rethrow(ex)
  end

  res.status == 404 && req.method == OPTIONS && return preflight_response()

  ! in(response_type(params), sessionless) && Genie.config.session_auto_start && Sessions.persist(session)

  reqstatus = "$(req.target) $(res.status)\n"
  if res.status < 400
    @info reqstatus
  else
    @error reqstatus
  end

  res
end


"""
    route_ws_request(req::Request, msg::String, ws_client::HTTP.WebSockets.WebSocket, ip::IPv4 = Genie.config.server_host) :: String

First step in handling a web socket request: sets up @params collection, handles query vars, starts and persists sessions.
"""
function route_ws_request(req, msg::String, ws_client, ip::IPv4 = IPv4(Genie.config.server_host)) :: String
  params = Params()
  params.collection[:request_ipv4] = ip
  params.collection[Genie.PARAMS_WS_CLIENT] = ws_client

  extract_get_params(URI(req.target), params)

  Revise.revise()

  session = Genie.config.session_auto_start ? Sessions.load(Sessions.id(req)) : nothing

  match_channels(req, msg, ws_client, params, session)
end


"""
    negotiate_content(req::Request, res::Response, params::Params) :: Response

Computes the content-type of the `Response`, based on the information in the `Request`.
"""
function negotiate_content(req::HTTP.Request, res::HTTP.Response, params::Params) :: HTTP.Response
  headers = Dict(res.headers)

  function set_negotiated_content()
    params.collection[:response_type] = request_type(req)
    push!(res.headers, "Content-Type" => get(Genie.Renderer.CONTENT_TYPES, params.collection[:response_type], "text/html"))

    true
  end

  if haskey(params.collection, :response_type) && in(Symbol(params.collection[:response_type]), collect(keys(Genie.Renderer.CONTENT_TYPES)) )
    params.collection[:response_type] = Symbol(params.collection[:response_type])
    headers["Content-Type"] = Genie.Renderer.CONTENT_TYPES[params.collection[:response_type]]

    res.headers = [k for k in headers]

    return res
  end

  negotiation_header = haskey(headers, "Accept") ? "Accept" : ( haskey(headers, "Content-Type") ? "Content-Type" : "" )

  isempty(negotiation_header) && set_negotiated_content() && return res

  accept_parts = split(headers[negotiation_header], ";")

  isempty(accept_parts) && set_negotiated_content() && return res

  accept_order_parts = split(accept_parts[1], ",")

  isempty(accept_order_parts) && set_negotiated_content() && return res

  for mime in accept_order_parts
    if occursin("/", mime)
      content_type = split(mime, "/")[2] |> lowercase |> Symbol
      if haskey(Genie.Renderer.CONTENT_TYPES, content_type)
        params.collection[:response_type] = content_type
        headers["Content-Type"] = Genie.Renderer.CONTENT_TYPES[params.collection[:response_type]]

        res.headers = [k for k in headers]
        return res
      end
    end
  end

  set_negotiated_content() && return res
end


function Base.push!(collection, name::Symbol, item::Union{Route,Channel})
  collection[name] = item
end


"""
Named Genie routes constructors.
"""
function route(action::Function, path::String; method = GET, named::Union{Symbol,Nothing} = nothing) :: Route
  route(path, action, method = method, named = named)
end
function route(path::String, action::Function; method = GET, named::Union{Symbol,Nothing} = nothing) :: Route
  r = Route(method = method, path = path, action = action, name = named)

  if named === nothing
    r.name = routename(r)
  end

  Router.push!(_routes, r.name, r)
end


"""
Named Genie channels constructors.
"""
function channel(action::Function, path::String; named::Union{Symbol,Nothing} = nothing) :: Channel
  channel(path, action, named = named)
end
function channel(path::String, action::Function; named::Union{Symbol,Nothing} = nothing) :: Channel
  c = Channel(path = path, action = action, name = named)

  if named === nothing
    c.name = channelname(c)
  end

  Router.push!(_channels, c.name, c)
end


"""
    routename(params) :: Symbol

Computes the name of a route.
"""
function routename(params::Route) :: Symbol
  baptizer(params, String[lowercase(params.method)])
end


"""
    channelname(params) :: Symbol

Computes the name of a channel.
"""
@inline function channelname(params::Channel) :: Symbol
  baptizer(params, String[])
end


function baptizer(params::Union{Route,Channel}, parts::Vector{String}) :: Symbol
  for uri_part in split(params.path, "/", keepempty = false)
    startswith(uri_part, ":") && continue # we ignore named params
    push!(parts, lowercase(uri_part))
  end

  join(parts, "_") |> Symbol
end


"""
The list of the defined named routes.
"""
@inline function named_routes() :: OrderedDict{Symbol,Route}
  _routes
end
const namedroutes = named_routes


"""
    @routes

Collection of named routes
"""
macro routes()
  _routes
end


"""
    named_channels() :: Dict{Symbol,Any}

The list of the defined named channels.
"""
@inline function named_channels() :: OrderedDict{Symbol,Channel}
  _channels
end
const namedchannels = named_channels


"""
    @channels

Collection of named channels.
"""
macro channels()
  _channels
end


"""
Gets the `Route` correspoding to `routename`
"""
@inline function get_route(route_name::Symbol) :: Route
  haskey(named_routes(), route_name) ? named_routes()[route_name] : error("Route named `$route_name` is not defined")
end


"""
    routes() :: Vector{Route}

Returns a vector of defined routes.
"""
@inline function routes() :: Vector{Route}
  collect(values(_routes)) |> reverse
end


"""
    channels() :: Vector{Channel}

Returns a vector of defined channels.
"""
@inline function channels() :: Vector{Channel}
  collect(values(_channels)) |> reverse
end


"""
    delete!(routes, route_name::Symbol)

Removes the route with the corresponding name from the routes collection and returns the collection of remaining routes.
"""
@inline function delete!(routes::OrderedDict{Symbol,Route}, key::Symbol) :: OrderedDict{Symbol,Route}
  OrderedCollections.delete!(routes, key)
end


"""
Generates the HTTP link corresponding to `route_name` using the parameters in `d`.
"""
function to_link(route_name::Symbol, d::Dict{Symbol,T}; preserve_query::Bool = true, extra_query::Dict = Dict())::String where {T}
  route = get_route(route_name)

  result = String[]
  for part in split(route.path, "/")
    if occursin("#", part)
      part = split(part, "#")[1]
    end

    if startswith(part, ":")
      var_name = split(part, "::")[1][2:end] |> Symbol
      ( isempty(d) || ! haskey(d, var_name) ) && error("Route $route_name expects param $var_name")
      push!(result, pathify(d[var_name]))
      Base.delete!(d, var_name)
      continue
    end

    push!(result, part)
  end

  query_vars = Dict{String,String}()
  if preserve_query && haskey(task_local_storage(), :__params) && haskey(task_local_storage(:__params)[:REQUEST])
    query = URI(task_local_storage(:__params)[:REQUEST].target).query
    if ! isempty(query)
      for pair in split(query, '&')
        parts = split(pair, '=')
        query_vars[parts[1]] = parts[2]
      end
    end
  end

  for (k,v) in extra_query
    query_vars[string(k)] = string(v)
  end

  qv = String[]
  for (k,v) in query_vars
    push!(qv, "$k=$v")
  end

  join(result, "/") * ( ! isempty(qv) ? "?" : "" ) * join(qv, "&")
end


"""
Generates the HTTP link corresponding to `route_name` using the parameters in `route_params`.
"""
@inline function to_link(route_name::Symbol; preserve_query::Bool = true, extra_query::Dict = Dict(), route_params...) :: String
  to_link(route_name, route_params_to_dict(route_params), preserve_query = preserve_query, extra_query = extra_query)
end

const link_to = to_link
const linkto = link_to
const tolink = to_link
const toroute = to_link


"""
    route_params_to_dict(route_params)

Converts the route params to a `Dict`.
"""
@inline function route_params_to_dict(route_params) :: Dict{Symbol,Any}
  Dict{Symbol,Any}(route_params)
end


"""
"""
function action_controller_params(action::Function, params::Params) :: Nothing
  params.collection[:action_controller] = action |> string |> Symbol
  params.collection[:action] = nameof(action)
  params.collection[:controller] = (action |> typeof).name.module |> string |> Symbol

  nothing
end


"""
"""
function run_hook(controller::Module, hook_type::Symbol) :: Bool
  isdefined(controller, hook_type) || return false

  getfield(controller, hook_type) |> Base.invokelatest

  true
end


"""
    match_routes(req::Request, res::Response, session::Sessions.Session, params::Params) :: Response

Matches the invoked URL to the corresponding route, sets up the execution environment and invokes the controller method.
"""
function match_routes(req::HTTP.Request, res::HTTP.Response, session::Union{Genie.Sessions.Session,Nothing}, params::Params) :: HTTP.Response
  for r in routes()
    r.method != req.method && continue

    parsed_route, param_names, param_types = parse_route(r.path)

    uri = URI(to_uri(req.target))
    regex_route = try
      Regex("^" * parsed_route * "\$")
    catch
      @error "Invalid route $parsed_route"

      continue
    end

    occursin(regex_route, uri.path) || parsed_route == "/*" || continue

    params.collection = setup_base_params(req, res, params.collection, session)

    occursin("?", req.target) && extract_get_params(URI(to_uri(req.target)), params)

    extract_uri_params(uri.path, regex_route, param_names, param_types, params) || continue

    ispayload(req) && extract_post_params(req, params)
    ispayload(req) && extract_request_params(req, params)
    action_controller_params(r.action, params)

    res = negotiate_content(req, res, params)

    params.collection[Genie.PARAMS_ROUTE_KEY] = r

    task_local_storage(:__params, params.collection)

    controller = (r.action |> typeof).name.module

    return  try
              run_hook(controller, BEFORE_HOOK)
              result =  (isdev() ? Base.invokelatest(r.action) : (r.action)()) |> to_response
              run_hook(controller, AFTER_HOOK)

              result
            catch ex
              isa(ex, ExceptionalResponse) ? (return ex.response) : to_response(ex)
            end
  end

  error_404(req.target, req)
end


"""
    match_channels(req::Request, msg::String, ws_client::HTTP.WebSockets.WebSocket, params::Params, session::Sessions.Session) :: String

Matches the invoked URL to the corresponding channel, sets up the execution environment and invokes the channel controller method.
"""
function match_channels(req, msg::String, ws_client, params::Params, session::Union{Sessions.Session,Nothing}) :: String
  for c in channels()
    parsed_channel, param_names, param_types = parse_channel(c.path)

    payload::Dict{String,Any} = try
                                  Renderer.JSONParser.parse(msg)
                                catch ex
                                  Dict{String,Any}()
                                end

    uri = haskey(payload, "channel") ? "/" * payload["channel"] : "/"
    uri = haskey(payload, "message") ? uri * "/" * payload["message"] : uri

    haskey(payload, "payload") && (params.collection[:payload] = payload["payload"])

    regex_channel = Regex("^" * parsed_channel * "\$")

    (! occursin(regex_channel, uri)) && continue

    params.collection = setup_base_params(req, nothing, params.collection, session)

    extract_uri_params(uri, regex_channel, param_names, param_types, params) || continue

    action_controller_params(c.action, params)

    params.collection[Genie.PARAMS_CHANNEL_KEY] = c

    task_local_storage(:__params, params.collection)

    controller = (c.action |> typeof).name.module

    return  try
                run_hook(controller, BEFORE_HOOK)
                result = (isdev() ? Base.invokelatest(c.action) : (c.action)()) |> string
                run_hook(controller, AFTER_HOOK)

                result
              catch ex
                isa(ex, Exception) ? ex.msg : rethrow(ex)
              end
  end

  string("404 - Not found")
end


"""
    parse_route(route::String) :: Tuple{String,Vector{String},Vector{Any}}

Parses a route and extracts its named params and types.
"""
function parse_route(route::String) :: Tuple{String,Vector{String},Vector{Any}}
  parts = String[]
  param_names = String[]
  param_types = Any[]

  validation_match = "[\\w\\-\\.\\+\\,\\s\\%]+"

  for rp in split(route, "/", keepempty = false)
    if occursin("#", rp)
      x = split(rp, "#")
      rp = x[1]
      validation_match = x[2]
    end

    if startswith(rp, ":")
      param_type =  if occursin("::", rp)
                      x = split(rp, "::")
                      rp = x[1]
                      getfield(@__MODULE__, Symbol(x[2]))
                    else
                      Any
                    end
      param_name = rp[2:end]

      rp = """(?P<$param_name>$validation_match)"""

      push!(param_names, param_name)
      push!(param_types, param_type)
    end

    push!(parts, rp)
  end

  "/" * join(parts, "/"), param_names, param_types
end


"""
    parse_channel(channel::String) :: Tuple{String,Vector{String},Vector{Any}}

Parses a channel and extracts its named parms and types.
"""
function parse_channel(channel::String) :: Tuple{String,Vector{String},Vector{Any}}
  parts = String[]
  param_names = String[]
  param_types = Any[]

  for rp in split(channel, "/", keepempty = false)
    if startswith(rp, ":")
      param_type =  if occursin("::", rp)
                      x = split(rp, "::")
                      rp = x[1]
                      getfield(@__MODULE__, Symbol(x[2]))
                    else
                      Any
                    end
      param_name = rp[2:end]
      rp = """(?P<$param_name>[\\w\\-]+)"""
      push!(param_names, param_name)
      push!(param_types, param_type)
    end
    push!(parts, rp)
  end

  "/" * join(parts, "/"), param_names, param_types
end


"""
    extract_uri_params(uri::String, regex_route::Regex, param_names::Vector{String}, param_types::Vector{Any}, params::Params) :: Bool

Extracts params from request URI and sets up the `params` `Dict`.
"""
function extract_uri_params(uri::String, regex_route::Regex, param_names::Vector{String}, param_types::Vector{Any}, params::Params) :: Bool
  matches = match(regex_route, uri)

  i = 1
  for param_name in param_names
    try
      params.collection[Symbol(param_name)] = convert(param_types[i], matches[param_name])
    catch ex
      @error "Failed to match URI params between $(param_types[i])::$(typeof(param_types[i])) and $(matches[param_name])::$(typeof(matches[param_name]))"
      @error ex

      return false
    end

    i += 1
  end

  true # this must be bool cause it's used in bool context for chaining
end


"""
    extract_get_params(uri::URI, params::Params) :: Bool

Extracts query vars and adds them to the execution `params` `Dict`.
"""
function extract_get_params(uri::URI, params::Params) :: Bool
  # GET params
  if ! isempty(uri.query)
    for query_part in split(uri.query, "&")
      qp = split(query_part, "=")
      (size(qp)[1] == 1) && (push!(qp, ""))

      k = Symbol(URIParser.unescape(qp[1]))
      v = URIParser.unescape(qp[2])
      params.collection[k] = params.collection[Genie.PARAMS_GET_KEY][k] = v
    end
  end

  true # this must be bool cause it's used in bool context for chaining
end


"""
    extract_post_params(req::Request, params::Params) :: Nothing

Parses POST variables and adds the to the `params` `Dict`.
"""
function extract_post_params(req::HTTP.Request, params::Params) :: Nothing
  ispayload(req) || return nothing

  input = Input.all(req)

  for (k, v) in input.post
    nested_keys(k, v, params)

    k = Symbol(k)
    params.collection[k] = params.collection[Genie.PARAMS_POST_KEY][k] = v
  end

  params.collection[Genie.PARAMS_FILES] = input.files

  nothing
end


"""
"""
function extract_request_params(req::HTTP.Request, params::Params) :: Nothing
  ispayload(req) || return nothing

  params.collection[Genie.PARAMS_RAW_PAYLOAD] = String(req.body)

  if request_type_is(req, :json) && content_length(req) > 0
    try
      params.collection[Genie.PARAMS_JSON_PAYLOAD] = Renderer.JSONParser.parse(params.collection[Genie.PARAMS_RAW_PAYLOAD])
    catch ex
      @error sprint(showerror, ex)
      @warn "Setting @params(:JSON_PAYLOAD) to Nothing"

      params.collection[Genie.PARAMS_JSON_PAYLOAD] = nothing
    end
  else
    params.collection[Genie.PARAMS_JSON_PAYLOAD] = nothing
  end

  nothing
end


"""
"""
function content_type(req::HTTP.Request) :: String
  get(Genie.HTTPUtils.Dict(req), "content-type", "")
end
function content_type() :: String
  content_type(_params_(Genie.PARAMS_REQUEST_KEY))
end


"""
"""
function content_length(req::HTTP.Request) :: Int
  parse(Int, get(Genie.HTTPUtils.Dict(req), "content-length", "0"))
end
function content_length() :: Int
  content_length(_params_(Genie.PARAMS_REQUEST_KEY))
end


"""
"""
function request_type_is(req::HTTP.Request, request_type::Symbol) :: Bool
  ! in(request_type, keys(request_mappings) |> collect) && error("Unknown request type $request_type - expected one of $(keys(request_mappings) |> collect).")

  occursin(request_mappings[request_type], content_type(req)) && return true

  false
end
function request_type_is(request_type::Symbol) :: Bool
  request_type_is(_params_(Genie.PARAMS_REQUEST_KEY), request_type)
end


"""
"""
function request_type(req::HTTP.Request) :: Symbol
  for (k,v) in request_mappings
    if occursin(v, content_type(req))
      return k
    end
  end

  return :unknown
end
function request_type() :: Symbol
  request_type(_params_(Genie.PARAMS_REQUEST_KEY))
end


"""
    nested_keys(k::String, v, params::Params) :: Nothing

Utility function to process nested keys and set them up in `params`.
"""
function nested_keys(k::String, v, params::Params) :: Nothing
  if occursin(".", k)
    parts = split(k, ".", limit = 2)
    nested_val_key = Symbol(parts[1])

    if haskey(params.collection, nested_val_key) && isa(params.collection[nested_val_key], Dict)
      ! haskey(params.collection[nested_val_key], Symbol(parts[2])) && (params.collection[nested_val_key][Symbol(parts[2])] = v)
    elseif ! haskey(params.collection, nested_val_key)
      params.collection[nested_val_key] = Dict()
      params.collection[nested_val_key][Symbol(parts[2])] = v
    end
  end

  nothing
end


"""
    setup_base_params(req::Request, res::Response, params::Dict{Symbol,Any}, session::Sessions.Session) :: Dict{Symbol,Any}

Populates `params` with default environment vars.
"""
function setup_base_params(req::HTTP.Request, res::Union{HTTP.Response,Nothing}, params::Dict{Symbol,Any}, session::Union{Genie.Sessions.Session,Nothing}) :: Dict{Symbol,Any}
  params[Genie.PARAMS_REQUEST_KEY]   = req
  params[Genie.PARAMS_RESPONSE_KEY]  = res
  params[Genie.PARAMS_SESSION_KEY]   = session
  params[Genie.PARAMS_FLASH_KEY]     = Genie.config.session_auto_start ?
                                       begin
                                        s = Genie.Sessions.get(session, Genie.PARAMS_FLASH_KEY)
                                        if isnull(s)
                                          ""
                                        else
                                          ss = Base.get(s)
                                          Genie.Sessions.unset!(session, Genie.PARAMS_FLASH_KEY)
                                          ss
                                        end
                                       end : ""

  params[Genie.PARAMS_POST_KEY]      = Dict{Symbol,Any}()
  params[Genie.PARAMS_GET_KEY]       = Dict{Symbol,Any}()

  params[Genie.PARAMS_FILES]         = Dict{String,HttpFile}()

  params
end


"""
    to_response(action_result) :: Response

Converts the result of invoking the controller action to a `Response`.
"""
function to_response(action_result) :: HTTP.Response
  isa(action_result, HTTP.Response) && return action_result

  if isa(action_result, Tuple)
    HTTP.Response(action_result...)
  elseif isa(action_result, Nothing)
    HTTP.Response("")
  elseif isa(action_result, String)
    Renderer.respond(action_result)
  elseif isa(action_result, ExceptionalResponse)
    action_result.response
  elseif isa(action_result, RuntimeException)
    throw(action_result)
  elseif isa(action_result, Exception)
    throw(action_result)
  else
    HTTP.Response(string(action_result))
  end
end


"""
"""
macro params()
  quote
    haskey(task_local_storage(), :__params) ? task_local_storage(:__params) : Dict{Symbol,Any}()
  end
end
macro params(key)
  :((@params)[$key])
end
macro params(key, default)
  quote
    haskey(@params, $key) ? @params($key) : $default
  end
end
function _params_()
  task_local_storage(:__params)
end
function _params_(key::Union{String,Symbol})
  task_local_storage(:__params)[key]
end


"""
"""
macro request()
  :(@params(Genie.PARAMS_REQUEST_KEY))
end


"""
    response_type{T}(params::Dict{Symbol,T}) :: Symbol
    response_type(params::Params) :: Symbol

Returns the content-type of the current request-response cycle.
"""
function response_type(params::Dict{Symbol,T})::Symbol where {T}
  haskey(params, :response_type) ? params[:response_type] : Genie.Renderer.DEFAULT_CONTENT_TYPE
end
function response_type(params::Params) :: Symbol
  response_type(params.collection)
end
function response_type() :: Symbol
  response_type(@params())
end


"""
    response_type{T}(check::Symbol, params::Dict{Symbol,T}) :: Bool

Checks if the content-type of the current request-response cycle matches `check`.
"""
function response_type(check::Symbol, params::Dict{Symbol,T})::Bool where {T}
  check == response_type(params)
end


const responsetype = response_type


"""
    serve_error_file_500(ex::Exception, params::Dict{Symbol,Any} = Dict{Symbol,Any}()) :: Response

Returns the default 500 error page.
"""
function serve_error_file_500(ex::Exception, params::Dict{Symbol,Any} = Dict{Symbol,Any}()) :: HTTP.Response
  serve_error_file( 500,
                    string(ex) *
                    "<br/><br/>" *
                    join(catch_stacktrace(), "<br/>") *
                    "<hr/>" *
                    string(params)
                  )
end


"""
    append_to_routes_file(content::String) :: Nothing

Appends `content` to the app's route file.
"""
function append_to_routes_file(content::String) :: Nothing
  open(Genie.ROUTES_FILE_NAME, "a") do io
    write(io, "\n" * content)
  end

  nothing
end


"""
    is_static_file(resource::String) :: Bool

Checks if the requested resource is a static file.
"""
function is_static_file(resource::String) :: Bool
  isfile(file_path(to_uri(resource).path))
end


"""
    to_uri(resource::String) :: URI

Attempts to convert `resource` to URI
"""
function to_uri(resource::String) :: URI
  try
    URI(resource)
  catch ex
    qp = URIParser.query_params(resource) |> keys |> collect
    escaped_resource = join(map( x -> ( startswith(x, "/") ? escape_resource_path(string(x)) : URIParser.escape(string(x)) ) * "=" * URIParser.escape(URIParser.query_params(resource)[string(x)]), qp ), "&")

    URI(escaped_resource)
  end
end


"""
"""
function escape_resource_path(resource::String)
  startswith(resource, "/") || return resource
  resource = resource[2:end]

  "/" * join(map(x -> URIParser.escape(x), split(resource, "?")), "?")
end


"""
    serve_static_file(resource::String) :: Response

Reads the static file and returns the content as a `Response`.
"""
function serve_static_file(resource::String; root = Genie.DOC_ROOT_PATH) :: HTTP.Response
  startswith(resource, "/") || (resource = "/$resource")
  resource_path = try
                    URI(resource).path
                  catch ex
                    resource
                  end
  f = file_path(resource_path, root = root)

  if isfile(f)
    HTTP.Response(200, file_headers(f), body = read(f, String))
  else
    bundled_path = joinpath(@__DIR__, "..", "files", "static", resource[2:end])
    if isfile(bundled_path)
      HTTP.Response(200, file_headers(bundled_path), body = read(bundled_path, String))
    else
      @error "404 Not Found $f"
      error_404(resource)
    end
  end
end


"""
"""
function preflight_response() :: HTTP.Response
  HTTP.Response(200, Genie.config.cors_headers, body = "Success")
end


"""
"""
function error_404(resource::String = "", req::HTTP.Request = HTTP.Request("", "", ["Content-Type" => request_mappings[:html]])) :: HTTP.Response
  if request_type_is(req, :json)
    HTTP.Response(404, ["Content-Type" => request_mappings[:json]], body = """{ "error": "404 - NOT FOUND" }""")
  elseif request_type_is(req, :text)
    HTTP.Response(404, ["Content-Type" => request_mappings[:text]], body = "Error: 404 - NOT FOUND")
  else
    serve_error_file(404, resource)
  end
end


"""
"""
function error_500(error_message::String = "", req::HTTP.Request = HTTP.Request("", "", ["Content-Type" => request_mappings[:html]])) :: HTTP.Response
  if request_type_is(req, :json)
    HTTP.Response(500, ["Content-Type" => request_mappings[:json]], body = Renderer.JSONParser.json(Dict("error" => "500 - $error_message")))
  elseif request_type_is(req, :text)
    HTTP.Response(500, ["Content-Type" => request_mappings[:text]], body = "Error: 500 - $error_message")
  else
    serve_error_file(500, error_message, @params)
  end
end


"""
"""
function error_xxx(error_message::String = "", req::HTTP.Request = HTTP.Request("", "", ["Content-Type" => request_mappings[:html]]); error_info::String = "", error_code::Int = 500) :: HTTP.Response
  if request_type_is(req, :json)
    HTTP.Response(error_code, ["Content-Type" => request_mappings[:json]], body = Renderer.JSONParser.json(Dict("error" => "500 - $error_message")))
  elseif request_type_is(req, :text)
    HTTP.Response(error_code, ["Content-Type" => request_mappings[:text]], body = "Error: 500 - $error_message")
  else
    serve_error_file(error_code, error_message, @params, error_info = error_info)
  end
end


function err(error_message::String; error_info::String = "", error_code::Int = 500) :: HTTP.Response
  error_xxx(error_message, @params(:REQUEST), error_info = error_info, error_code = error_code)
end


"""
    serve_error_file(error_code::Int, error_message::String = "", params::Dict{Symbol,Any} = Dict{Symbol,Any}()) :: Response

Serves the error file correspoding to `error_code` and current environment.
"""
function serve_error_file(error_code::Int, error_message::String = "", params::Dict{Symbol,Any} = Dict{Symbol,Any}(); error_info::String = "") :: HTTP.Response
  ERROR_DESCRIPTION_MAX_LENGTH = 1000

  page_code = error_code in [404, 500] ? "$error_code" : "xxx"

  try
    error_page_file = isfile(joinpath(Genie.DOC_ROOT_PATH, "error-$page_code.html")) ?
                        joinpath(Genie.DOC_ROOT_PATH, "error-$page_code.html") :
                          joinpath(@__DIR__, "..", "files", "static", "error-$page_code.html")

    error_page =  open(error_page_file) do f
                    read(f, String)
                  end

    if error_code == 500
      error_page = replace(error_page, "<error_description/>"=>split(error_message, "\n")[1])

      error_message = if Genie.Configuration.isdev()
                      """$("#" ^ 25) ERROR STACKTRACE $("#" ^ 25)\n$error_message                                     $("\n" ^ 3)""" *
                      """$("#" ^ 25)  REQUEST PARAMS  $("#" ^ 25)\n$(Millboard.table(params))                         $("\n" ^ 3)""" *
                      """$("#" ^ 25)     ROUTES       $("#" ^ 25)\n$(Millboard.table(Router.named_routes() |> Dict))  $("\n" ^ 3)""" *
                      """$("#" ^ 25)    JULIA ENV     $("#" ^ 25)\n$ENV                                               $("\n" ^ 1)"""
      else
        ""
      end

      error_page = replace(error_page, "<error_message/>"=>escapeHTML(error_message))
    elseif error_code == 404
      error_page = replace(error_page, "<error_message/>"=>error_message)
    else
      error_page = replace(replace(error_page, "<error_message/>"=>error_message), "<error_info/>"=>error_info)
    end

    HTTP.Response(error_code, ["Content-Type"=>"text/html"], body = error_page)
  catch ex
    @error ex
    HTTP.Response(error_code, ["Content-Type"=>"text/html"], body = "Error $page_code: $error_message")
  end
end


"""
    file_path(resource::String; within_doc_root = true) :: String

Returns the path to a resource file. If `within_doc_root` it will automatically prepend the document root to `resource`.
"""
function file_path(resource::String; within_doc_root = true, root = Genie.DOC_ROOT_PATH) :: String
  within_doc_root = within_doc_root && root == Genie.DOC_ROOT_PATH
  joinpath(within_doc_root ? Genie.config.server_document_root : root, resource[(startswith(resource, "/") ? 2 : 1):end])
end
const filepath = file_path


"""
    pathify(x) :: String

Returns a proper URI path from a string `x`.
"""
pathify(x) :: String = replace(string(x), " "=>"-") |> lowercase |> URIParser.escape


"""
    file_extension(f) :: String

Returns the file extesion of `f`.
"""
file_extension(f) :: String = ormatch(match(r"(?<=\.)[^\.\\/]*$", f), "")
const fileextension = file_extension


"""
    file_headers(f) :: Dict{String,String}

Returns the file headers of `f`.
"""
function file_headers(f) :: Vector{Pair{String,String}}
  ["Content-Type" => get(mimetypes, file_extension(f), "application/octet-stream")]
end

ormatch(r::RegexMatch, x) = r.match
ormatch(r::Nothing, x) = x

end