"""
Parses requests and extracts parameters, setting up the call variables and invoking
the appropiate route handler function.
"""
module Router

import Revise
import Reexport, Logging
import HTTP, HttpCommon, Sockets, Millboard, Dates, OrderedCollections, JSON3
import Genie

include("mimetypes.jl")

export route, routes, channel, channels, serve_static_file
export GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD
export tolink, linkto, responsetype, toroute
export params, query, post, headers, request

Reexport.@reexport using HttpCommon

const GET     = "GET"
const POST    = "POST"
const PUT     = "PUT"
const PATCH   = "PATCH"
const DELETE  = "DELETE"
const OPTIONS = "OPTIONS"
const HEAD    = "HEAD"

const ROUTE_CATCH_ALL = "/*"
const ROUTE_CACHE = Dict{String,Tuple{String,Vector{String},Vector{Any}}}()

const request_mappings = Dict{Symbol,String}(
  :text       => "text/plain",
  :html       => "text/html",
  :json       => "application/json",
  :javascript => "application/javascript",
  :form       => "application/x-www-form-urlencoded",
  :multipart  => "multipart/form-data",
  :file       => "application/octet-stream",
  :xml        => "text/xml"
)

const pre_match_hooks = Function[]
const pre_response_hooks = Function[]
const content_negotiation_hooks = Function[]


"""
    mutable struct Route

Representation of a route object
"""
mutable struct Route
  method::String
  path::String
  action::Function
  name::Union{Symbol,Nothing}
  context::Module
end

Route(; method::String = GET, path::String = "", action::Function = (() -> error("Route not set")), name::Union{Symbol,Nothing} = nothing, context::Module = @__MODULE__) = Route(method, path, action, name, context)


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


const _routes = OrderedCollections.OrderedDict{Symbol,Route}()
const _channels = OrderedCollections.OrderedDict{Symbol,Channel}()


"""
    mutable struct Params{T}

Collection of key value pairs representing the parameters of the current request - response cycle.
"""
mutable struct Params{T}
  collection::Dict{Symbol,T}
end
Params() = Params(setup_base_params())

Base.Dict(params::Params) = params.collection

Base.getindex(params::Params, keys...) = getindex(Dict(params), keys...)
Base.getindex(params::Pair, keys...) = getindex(Dict(params), keys...)


"""
    _params_()

Reference to the request variables collection.
"""
function _params_()
  task_local_storage(:__params)
end
function _params_(key::Union{String,Symbol})
  task_local_storage(:__params)[key]
end
function _params_(key::Union{String,Symbol}, value::Any)
  task_local_storage(:__params)[key] = value
end


"""
    ispayload(req::HTTP.Request)

True if the request can carry a payload - that is, it's a `POST`, `PUT`, or `PATCH` request
"""
ispayload(req::HTTP.Request) = req.method in [POST, PUT, PATCH]


"""
    route_request(req::Request, res::Response) :: Response

First step in handling a request: sets up params collection, handles query vars, negotiates content.
"""
function route_request(req::HTTP.Request, res::HTTP.Response) :: HTTP.Response
  params = Params()

  for f in unique(content_negotiation_hooks)
    req, res, params.collection = f(req, res, params.collection)
  end

  if is_static_file(req.target)
    Genie.config.server_handle_static_files && return serve_static_file(req.target)

    return error(req.target, response_mime(), Val(404))
  end

  Genie.Configuration.isdev() && Revise.revise()

  for f in unique(pre_match_hooks)
    req, res, params.collection = f(req, res, params.collection)
  end

  res = match_routes(req, res, params)

  res.status == 404 && req.method == OPTIONS && return preflight_response()

  for f in unique(pre_response_hooks)
    req, res, params.collection = f(req, res, params.collection)
  end

  reqstatus = "$(req.method) $(req.target) $(res.status)\n"

  if Genie.config.log_requests
    if res.status < 400
      @info reqstatus
    else
      @error reqstatus
    end
  end

  req.method == HEAD && (res.body = UInt8[])

  res
end


"""
    route_ws_request(req::Request, msg::String, ws_client::HTTP.WebSockets.WebSocket) :: String

First step in handling a web socket request: sets up params collection, handles query vars.
"""
function route_ws_request(req, msg::String, ws_client) :: String
  params = Params()

  params.collection[Genie.PARAMS_WS_CLIENT] = ws_client

  extract_get_params(HTTP.URIs.URI(req.target), params)

  Genie.Configuration.isdev() && Revise.revise()

  match_channels(req, msg, ws_client, params)
end


function Base.push!(collection, name::Symbol, item::Union{Route,Channel})
  collection[name] = item
end


"""
Named Genie routes constructors.
"""
function route(action::Function, path::String; method = GET, named::Union{Symbol,Nothing} = nothing, context::Module = @__MODULE__) :: Route
  route(path, action, method = method, named = named, context = context)
end
function route(path::String, action::Function; method = GET, named::Union{Symbol,Nothing} = nothing, context::Module = @__MODULE__) :: Route
  r = Route(method = method, path = path, action = action, name = named, context = context)

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
function channelname(params::Channel) :: Symbol
  baptizer(params, String[])
end


"""
    baptizer(params::Union{Route,Channel}, parts::Vector{String}) :: Symbol

Generates default names for routes and channels.
"""
function baptizer(params::Union{Route,Channel}, parts::Vector{String}) :: Symbol
  for uri_part in split(params.path, '/', keepempty = false)
    startswith(uri_part, ":") && continue # we ignore named params
    push!(parts, lowercase(uri_part))
  end

  join(parts, "_") |> Symbol
end


"""
The list of the defined named routes.
"""
function named_routes() :: OrderedCollections.OrderedDict{Symbol,Route}
  _routes
end
const namedroutes = named_routes


"""
    named_channels() :: Dict{Symbol,Any}

The list of the defined named channels.
"""
function named_channels() :: OrderedCollections.OrderedDict{Symbol,Channel}
  _channels
end
const namedchannels = named_channels


"""
Gets the `Route` correspoding to `routename`
"""
function get_route(route_name::Symbol; default::Union{Route,Nothing} = Route()) :: Route
  haskey(named_routes(), route_name) ?
    named_routes()[route_name] :
    (if default === nothing
      Base.error("Route named `$route_name` is not defined")
    else
      @warn "Route named `$route_name` is not defined"
      default
    end)
end


"""
    routes() :: Vector{Route}

Returns a vector of defined routes.
"""
function routes() :: Vector{Route}
  collect(values(_routes)) |> reverse
end


"""
    channels() :: Vector{Channel}

Returns a vector of defined channels.
"""
function channels() :: Vector{Channel}
  collect(values(_channels)) |> reverse
end


"""
    delete!(routes, route_name::Symbol)

Removes the route with the corresponding name from the routes collection and returns the collection of remaining routes.
"""
function delete!(routes::OrderedCollections.OrderedDict{Symbol,Route}, key::Symbol) :: OrderedCollections.OrderedDict{Symbol,Route}
  OrderedCollections.delete!(routes, key)
end


"""
Generates the HTTP link corresponding to `route_name` using the parameters in `d`.
"""
function to_link(route_name::Symbol, d::Dict{Symbol,T}; preserve_query::Bool = true, extra_query::Dict = Dict())::String where {T}
  route = get_route(route_name)

  result = String[]
  for part in split(route.path, '/')
    if occursin("#", part)
      part = split(part, "#")[1] |> string
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
  if preserve_query && haskey(task_local_storage(), :__params) && haskey(task_local_storage(:__params), :REQUEST)
    query = HTTP.URIs.URI(task_local_storage(:__params)[:REQUEST].target).query
    if ! isempty(query)
      for pair in split(query, '&')
        try
          parts = split(pair, '=')
          query_vars[parts[1]] = parts[2]
        catch ex
          # @error ex
        end
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

  join(result, '/') * ( ! isempty(qv) ? '?' : "" ) * join(qv, '&')
end


"""
Generates the HTTP link corresponding to `route_name` using the parameters in `route_params`.
"""
function to_link(route_name::Symbol; preserve_query::Bool = true, extra_query::Dict = Dict(), route_params...) :: String
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
function route_params_to_dict(route_params) :: Dict{Symbol,Any}
  Dict{Symbol,Any}(route_params)
end


"""
    action_controller_params(action::Function, params::Params) :: Nothing

Sets up the :action_controller, :action, and :controller key - value pairs of the `params` collection.
"""
function action_controller_params(action::Function, params::Params) :: Nothing
  params.collection[:action_controller] = action |> string |> Symbol
  params.collection[:action] = nameof(action)
  params.collection[:controller] = (action |> typeof).name.module |> string |> Symbol

  nothing
end




"""
    match_routes(req::Request, res::Response, params::Params) :: Response

Matches the invoked URL to the corresponding route, sets up the execution environment and invokes the controller method.
"""
function match_routes(req::HTTP.Request, res::HTTP.Response, params::Params) :: HTTP.Response
  uri = HTTP.URIs.URI(req.target)

  for r in routes()
    # method must match but we can also handle HEAD requests with GET routes
    (r.method == req.method) || (r.method == GET && req.method == HEAD) || continue

    parsed_route, param_names, param_types = Genie.Configuration.isprod() ? get!(ROUTE_CACHE, r.path, parse_route(r.path, context = r.context)) : parse_route(r.path, context = r.context)

    regex_route = try
      Regex("^" * parsed_route * "\$")
    catch
      @error "Invalid route $parsed_route"

      continue
    end

    occursin(regex_route, string(uri.path)) || parsed_route == ROUTE_CATCH_ALL || continue

    params.collection = setup_base_params(req, res, params.collection)
    task_local_storage(:__params, params.collection)

    occursin("?", req.target) && extract_get_params(HTTP.URIs.URI(req.target), params)

    extract_uri_params(uri.path |> string, regex_route, param_names, param_types, params) || continue

    ispayload(req) && extract_post_params(req, params)
    ispayload(req) && extract_request_params(req, params)
    action_controller_params(r.action, params)

    for f in unique(content_negotiation_hooks)
      req, res, params.collection = f(req, res, params.collection)
    end

    params.collection[Genie.PARAMS_ROUTE_KEY] = r

    get!(params.collection, Genie.PARAMS_MIME_KEY, MIME(request_type(req)))

    controller = (r.action |> typeof).name.module

    return  try
              try
                (r.action)() |> to_response
              catch ex1
                if isa(ex1, MethodError) && string(ex1.f) == string(r.action)
                  Base.invokelatest(r.action) |> to_response
                else
                  rethrow(ex1)
                end
              end
            catch ex
              return handle_exception(ex)
            end
  end

  error(req.target, response_mime(params.collection), Val(404))
end


function handle_exception(ex::Genie.Exceptions.ExceptionalResponse)
  ex.response
end

function handle_exception(ex::Genie.Exceptions.RuntimeException)
  rethrow(ex)
end

function handle_exception(ex::Genie.Exceptions.InternalServerException)
  error(ex.message, response_mime(), Val(500))
end

function handle_exception(ex::Genie.Exceptions.NotFoundException)
  error(ex.resource, response_mime(), Val(404))
end

function handle_exception(ex::Exception)
  rethrow(ex)
end


"""
    match_channels(req::Request, msg::String, ws_client::HTTP.WebSockets.WebSocket, params::Params) :: String

Matches the invoked URL to the corresponding channel, sets up the execution environment and invokes the channel controller method.
"""
function match_channels(req, msg::String, ws_client, params::Params) :: String
  payload::Dict{String,Any} = try
    JSON3.read(msg, Dict{String,Any})
  catch ex
    Dict{String,Any}()
  end

  uri = haskey(payload, "channel") ? '/' * payload["channel"] : '/'
  uri = haskey(payload, "message") ? uri * '/' * payload["message"] : uri

  for c in channels()
    parsed_channel, param_names, param_types = parse_channel(c.path)

    haskey(payload, "payload") && (params.collection[:payload] = payload["payload"])

    regex_channel = Regex("^" * parsed_channel * "\$")

    (! occursin(regex_channel, uri)) && continue

    params.collection = setup_base_params(req, nothing, params.collection)
    task_local_storage(:__params, params.collection)

    extract_uri_params(uri, regex_channel, param_names, param_types, params) || continue

    action_controller_params(c.action, params)

    params.collection[Genie.PARAMS_CHANNELS_KEY] = c

    controller = (c.action |> typeof).name.module

    return  try
                result = try
                  (c.action)() |> string
                catch ex1
                  if isa(ex1, MethodError) && string(ex1.f) == string(c.action)
                    Base.invokelatest(c.action) |> string
                  else
                    rethrow(ex1)
                  end
                end

                result
              catch ex
                isa(ex, Exception) ? sprint(showerror, ex) : rethrow(ex)
              end
  end

  string("ERROR : 404 - Not found")
end


"""
    parse_route(route::String, context::Module = @__MODULE__) :: Tuple{String,Vector{String},Vector{Any}}

Parses a route and extracts its named params and types. `context` is used to access optional route parts types.
"""
function parse_route(route::String; context::Module = @__MODULE__) :: Tuple{String,Vector{String},Vector{Any}}
  parts = String[]
  param_names = String[]
  param_types = Any[]

  if occursin('#', route) || occursin(':', route)
    validation_match = "[\\w\\-\\.\\+\\,\\s\\%]+"

    for rp in split(route, '/', keepempty = false)
      if occursin("#", rp)
        x = split(rp, "#")
        rp = x[1] |> string
        validation_match = x[2]
      end

      if startswith(rp, ":")
        param_type =  if occursin("::", rp)
                        x = split(rp, "::")
                        rp = x[1] |> string
                        getfield(context, Symbol(x[2]))
                      else
                        Any
                      end
        param_name = rp[2:end] |> string

        rp = """(?P<$param_name>$validation_match)"""

        push!(param_names, param_name)
        push!(param_types, param_type)
      end

      push!(parts, rp)
    end
  else
    parts = split(route, '/', keepempty = false)
  end

  '/' * join(parts, '/'), param_names, param_types
end


"""
    parse_channel(channel::String) :: Tuple{String,Vector{String},Vector{Any}}

Parses a channel and extracts its named parms and types.
"""
function parse_channel(channel::String) :: Tuple{String,Vector{String},Vector{Any}}
  parts = String[]
  param_names = String[]
  param_types = Any[]

  if occursin(':', channel)
    for rp in split(channel, '/', keepempty = false)
      if startswith(rp, ":")
        param_type =  if occursin("::", rp)
                        x = split(rp, "::")
                        rp = x[1] |> string
                        getfield(@__MODULE__, Symbol(x[2]))
                      else
                        Any
                      end
        param_name = rp[2:end] |> string
        rp = """(?P<$param_name>[\\w\\-]+)"""
        push!(param_names, param_name)
        push!(param_types, param_type)
      end
      push!(parts, rp)
    end
  else
    parts = split(channel, '/', keepempty = false)
  end

  '/' * join(parts, '/'), param_names, param_types
end

parse_param(param_type::Type{<:Number}, param::AbstractString) = parse(param_type, param)
parse_param(param_type::Type{T}, param::S) where {T, S} = convert(param_type, param)

"""
    extract_uri_params(uri::String, regex_route::Regex, param_names::Vector{String}, param_types::Vector{Any}, params::Params) :: Bool

Extracts params from request URI and sets up the `params` `Dict`.
"""
function extract_uri_params(uri::String, regex_route::Regex, param_names::Vector{String}, param_types::Vector{Any}, params::Params) :: Bool
  matches = match(regex_route, uri)

  i = 1
  for param_name in param_names
    try
      params.collection[Symbol(param_name)] = parse_param(param_types[i], matches[param_name])
    catch _
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
function extract_get_params(uri::HTTP.URIs.URI, params::Params) :: Bool
  # GET params
  if ! isempty(uri.query)
    if occursin("[]", uri.query)
      for query_part in split(uri.query, "&")
        qp = split(query_part, "=")
        (size(qp)[1] == 1) && (push!(qp, ""))

        k = Symbol(HTTP.URIs.unescapeuri(qp[1]))
        v = HTTP.URIs.unescapeuri(qp[2])

        # collect values like x[] in an array
        if endswith(string(k), "[]") && haskey(params.collection, k)
          if isa(params.collection, Vector)
            push!(params.collection[k], v)
            params.collection[Genie.PARAMS_GET_KEY][k] = params.collection[k]
          else
            params.collection[k] = params.collection[Genie.PARAMS_GET_KEY][k] = [params.collection[k], v]
          end
        else
          params.collection[k] = params.collection[Genie.PARAMS_GET_KEY][k] = v
        end
      end
    else
      for (k,v) in HTTP.URIs.queryparams(uri)
        k = Symbol(k)
        params.collection[k] = params.collection[Genie.PARAMS_GET_KEY][k] = v
      end
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

  try
    input = Genie.Input.all(req)

    for (k, v) in input.post
      nested_keys(k, v, params)

      k = Symbol(k)
      params.collection[k] = params.collection[Genie.PARAMS_POST_KEY][k] = v
    end

    params.collection[Genie.PARAMS_FILES] = input.files
  catch ex
    @error ex
  end

  nothing
end


"""
    extract_request_params(req::HTTP.Request, params::Params) :: Nothing

Sets up the `params` key-value pairs corresponding to a JSON payload.
"""
function extract_request_params(req::HTTP.Request, params::Params) :: Nothing
  ispayload(req) || return nothing

  req_body = String(req.body)

  params.collection[Genie.PARAMS_RAW_PAYLOAD] = req_body

  if request_type_is(req, :json) && content_length(req) > 0
    try
      params.collection[Genie.PARAMS_JSON_PAYLOAD] = JSON3.read(req_body) |> Dict
      params.collection[Genie.PARAMS_POST_KEY][Genie.PARAMS_JSON_PAYLOAD] = params.collection[Genie.PARAMS_JSON_PAYLOAD]
    catch ex
      @error ex
      @warn "Setting params(:JSON_PAYLOAD) to Nothing"

      params.collection[Genie.PARAMS_JSON_PAYLOAD] = nothing
    end
  else
    params.collection[Genie.PARAMS_JSON_PAYLOAD] = nothing
  end

  nothing
end


function Dict(o::JSON3.Object) :: Dict{String,Any}
  r = Dict{String,Any}()

  for f in keys(o)
    r[string(f)] = o[string(f)]
  end

  r
end


"""
    content_type(req::HTTP.Request) :: String

Gets the content-type of the request.
"""
function content_type(req::HTTP.Request) :: String
  get(Genie.HTTPUtils.Dict(req), "content-type", get(Genie.HTTPUtils.Dict(req), "accept", ""))
end


"""
    content_length(req::HTTP.Request) :: Int

Gets the content-length of the request.
"""
function content_length(req::HTTP.Request) :: Int
  parse(Int, get(Genie.HTTPUtils.Dict(req), "content-length", "0"))
end
function content_length() :: Int
  content_length(_params_(Genie.PARAMS_REQUEST_KEY))
end


"""
    request_type_is(req::HTTP.Request, request_type::Symbol) :: Bool

Checks if the request content-type is of a certain type.
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
    request_type(req::HTTP.Request) :: Symbol

Gets the request's content type.
"""
function request_type(req::HTTP.Request) :: Symbol
  accepted_encodings = split(content_type(req), ',')

  for accepted_encoding in accepted_encodings
    for (k,v) in request_mappings
      if occursin(v, accepted_encoding)
        return k
      end
    end
  end

  Symbol(accepted_encodings[1])
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
    setup_base_params(req::Request, res::Response, params::Dict{Symbol,Any}) :: Dict{Symbol,Any}

Populates `params` with default environment vars.
"""
function setup_base_params(req::HTTP.Request = HTTP.Request(), res::Union{HTTP.Response,Nothing} = req.response,
                            params::Dict{Symbol,Any} = Dict{Symbol,Any}()) :: Dict{Symbol,Any}
  params[Genie.PARAMS_REQUEST_KEY]   = req
  params[Genie.PARAMS_RESPONSE_KEY]  = res
  params[Genie.PARAMS_POST_KEY]      = Dict{Symbol,Any}()
  params[Genie.PARAMS_GET_KEY]       = Dict{Symbol,Any}()

  params[Genie.PARAMS_FILES]         = Dict{String,Genie.Input.HttpFile}()

  params
end


"""
    to_response(action_result) :: Response

Converts the result of invoking the controller action to a `Response`.
"""
to_response(action_result::HTTP.Response)::HTTP.Response = action_result
to_response(action_result::Tuple)::HTTP.Response = HTTP.Response(action_result...)
to_response(action_result::Vector)::HTTP.Response = HTTP.Response(join(action_result))
to_response(action_result::Nothing)::HTTP.Response = HTTP.Response("")
to_response(action_result::String)::HTTP.Response = HTTP.Response(action_result)
to_response(action_result::Genie.Exceptions.ExceptionalResponse)::HTTP.Response = action_result.response
to_response(action_result::Exception)::HTTP.Response = throw(action_result)
to_response(action_result::Any)::HTTP.Response = HTTP.Response(string(action_result))


"""
    function params()

The collection containing the request variables collection.
"""
function params()
  haskey(task_local_storage(), :__params) ? task_local_storage(:__params) : task_local_storage(:__params, Dict{Symbol,Any}())
end
function params(key)
  _params_()[key]
end
function params(key, default)
  get(_params_(), key, default)
end


"""
    function query

The collection containing the query request variables collection (GET params).
"""
function query()
  haskey(params(), Genie.PARAMS_GET_KEY) ? params(Genie.PARAMS_GET_KEY) : Dict()
end
function query(key)
  query()[key]
end
function query(key, default)
  get(query(), key, default)
end


"""
    function post

The collection containing the POST request variables collection.
"""
function post()
  haskey(params(), Genie.PARAMS_POST_KEY) ? params(Genie.PARAMS_POST_KEY) : Dict()
end
function post(key)
  post()[key]
end
function post(key, default)
  get(post(), key, default)
end


"""
    function request()

The request object.
"""
function request()
  params(Genie.PARAMS_REQUEST_KEY)
end


"""
    function headers()

The current request's headers (as a Dict)
"""
function headers()
  Dict{String,String}(request().headers)
end


"""
    response_type{T}(params::Dict{Symbol,T}) :: Symbol
    response_type(params::Params) :: Symbol

Returns the content-type of the current request-response cycle.
"""
function response_type(params::Dict{Symbol,T})::Symbol where {T}
  get(params, :response_type, request_type(params[Genie.PARAMS_REQUEST_KEY]))
end
function response_type(params::Params) :: Symbol
  response_type(params.collection)
end
function response_type() :: Symbol
  response_type(params())
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
  isfile(file_path(HTTP.URIs.URI(resource).path |> string))
end


"""
    escape_resource_path(resource::String)

Cleans up paths to resources.
"""
function escape_resource_path(resource::String)
  startswith(resource, '/') || return resource
  resource = resource[2:end]

  '/' * join(map(x -> HTTP.URIs.escapeuri(x), split(resource, '?')), '?')
end


"""
    serve_static_file(resource::String) :: Response

Reads the static file and returns the content as a `Response`.
"""
function serve_static_file(resource::String; root = Genie.config.server_document_root) :: HTTP.Response
  startswith(resource, '/') || (resource = "/$(resource)")
  resource_path = try
                    HTTP.URIs.URI(resource).path |> string
                  catch ex
                    resource
                  end
  f = file_path(resource_path, root = root)

  if isfile(f)
    return HTTP.Response(200, file_headers(f), body = read(f, String))
  elseif isdir(f)
    isfile(joinpath(f, "index.html")) && return serve_static_file(joinpath(f, "index.html"), root = root)
    isfile(joinpath(f, "index.htm")) && return serve_static_file(joinpath(f, "index.htm"), root = root)
  else
    bundled_path = joinpath(@__DIR__, "..", "files", "static", resource[2:end])
    if isfile(bundled_path)
      return HTTP.Response(200, file_headers(bundled_path), body = read(bundled_path, String))
    end
  end

  @error "404 Not Found $f"
  error(resource, response_mime(), Val(404))
end


"""
preflight_response() :: HTTP.Response

Sets up the preflight CORS response header.
"""
function preflight_response() :: HTTP.Response
  HTTP.Response(200, Genie.config.cors_headers, body = "Success")
end


"""
    response_mime()

Returns the MIME type of the response.
"""
function response_mime(params::Dict{Symbol,Any} = _params_())
  rm = get!(params, Genie.PARAMS_MIME_KEY, request_type(params[Genie.PARAMS_REQUEST_KEY]))

  if isempty(string(rm()))
    params[Genie.PARAMS_MIME_KEY] = request_type(params[Genie.PARAMS_REQUEST_KEY])
  end

  params[Genie.PARAMS_MIME_KEY]
end


"""
    error

Not implemented function for error response.
"""
function error end


function trymime(mime::Any)
  try
    mime()
  catch _
    mime
  end
end


function error(error_message::String, mime::Any, ::Val{500}; error_info::String = "") :: HTTP.Response
  HTTP.Response(500, ["Content-Type" => string(trymime(mime))], body = "500 Internal Error - $error_message. $error_info")
end


function error(error_message::String, mime::Any, ::Val{404}; error_info::String = "") :: HTTP.Response
  HTTP.Response(404, ["Content-Type" => string(trymime(mime))], body = "404 Not Found - $error_message. $error_info")
end


function error(error_code::Int, error_message::String, mime::Any; error_info::String = "") :: HTTP.Response
  HTTP.Response(error_code, ["Content-Type" => string(trymime(mime))], body = "$error_code Error - $error_message. $error_info")
end


"""
    file_path(resource::String; within_doc_root = true) :: String

Returns the path to a resource file. If `within_doc_root` it will automatically prepend the document root to `resource`.
"""
function file_path(resource::String; within_doc_root = true, root = Genie.config.server_document_root) :: String
  within_doc_root = within_doc_root && root == Genie.config.server_document_root
  joinpath(within_doc_root ? Genie.config.server_document_root : root, resource[(startswith(resource, '/') ? 2 : 1):end])
end
const filepath = file_path


"""
    pathify(x) :: String

Returns a proper URI path from a string `x`.
"""
pathify(x) :: String = replace(string(x), " "=>"-") |> lowercase |> HTTP.URIs.escapeuri


"""
    file_extension(f) :: String

Returns the file extesion of `f`.
"""
file_extension(f) :: String = ormatch(match(r"(?<=\.)[^\.\\/]*$", f), "")


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
