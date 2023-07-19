"""
Parses requests and extracts parameters, setting up the call variables and invoking
the appropriate route handler function.
"""
module Router

import Revise
import Reexport, Logging
import HTTP, HttpCommon, Sockets, Millboard, Dates, OrderedCollections, JSON3, MIMEs

using Genie
Reexport.@reexport using Genie.Context

export route, routes, channel, channels, download, serve_static_file, serve_file, responsetype
export GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD
export @get, @post, @put, @patch, @delete, @options, @head, @route
export params, query, post, headers, request, params!
export ispayload
export NOT_FOUND, INTERNAL_ERROR, BAD_REQUEST, CREATED, NO_CONTENT, OK
export RoutesGroup, group

Reexport.@reexport using HttpCommon

const GET     = "GET"
const POST    = "POST"
const PUT     = "PUT"
const PATCH   = "PATCH"
const DELETE  = "DELETE"
const OPTIONS = "OPTIONS"
const HEAD    = "HEAD"

const OK              = 200
const CREATED         = 201
const ACCEPTED        = 202
const NO_CONTENT      = 204
const BAD_REQUEST     = 400
const NOT_FOUND       = 404
const INTERNAL_ERROR  = 500

const ROUTE_CACHE = OrderedCollections.LittleDict{String,Tuple{String,Vector{String},Vector{Any}}}()

function request_mappings()
  mappings = ImmutableDict(:text => ["text/plain"])
  ImmutableDict(
    mappings,
    :html       => ["text/html"],
    :json       => ["application/json", "application/vnd.api+json"],
    :javascript => ["application/javascript"],
    :form       => ["application/x-www-form-urlencoded"],
    :multipart  => ["multipart/form-data"],
    :file       => ["application/octet-stream"],
    :xml        => ["text/xml"]
  )
end

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

Route(; method::String = GET,
        path::String = "",
        action::Function = (() -> error("Route not set")),
        name::Union{Symbol,Nothing} = nothing,
        context::Module = @__MODULE__) = Route(method, path, action, name, context)


"""
    mutable struct Channel

Representation of a WebSocket Channel object
"""
mutable struct Channel
  path::String
  action::Function
  name::Union{Symbol,Nothing}

  Channel(; path = "", action = (() -> error("Channel not set")), name = nothing) = new(path, action, name)
end


function Base.show(io::IO, r::Route)
  print(io, "[$(r.method)] $(r.path) => $(r.action) | :$(r.name)")
end
function Base.show(io::IO, c::Channel)
  print(io, "[WS] $(c.path) => $(c.action) | :$(c.name)")
end


Base.@kwdef mutable struct RoutesGroup
  routes::Vector{Route} = Route[]
  prefix::String = ""
  postfix::String = ""
end

function routes(g::RoutesGroup)
  for r in g.routes
    Router.delete!(r.name)

    if ! isempty(g.prefix)
      endswith(g.prefix, "/") && (g.prefix = g.prefix[1:end-1])
      startswith(r.path, "/") || (r.path = "/" * r.path)

      r.path = g.prefix * r.path
    end
    if ! isempty(g.postfix)
      endswith(r.path, "/") && (r.path = r.path[1:end-1])
      startswith(g.postfix, "/") || (g.postfix = "/" * g.postfix)

      r.path = r.path * g.postfix
    end

    route(r)
  end

  g
end

group(r::Vector{Route}; prefix = "", postfix = "") = RoutesGroup(r, prefix, postfix) |> routes


const _routes = OrderedCollections.LittleDict{Symbol,Route}()
const _channels = OrderedCollections.LittleDict{Symbol,Channel}()


"""
    ispayload(req::HTTP.Request)

True if the request can carry a payload - that is, it's a `POST`, `PUT`, or `PATCH` request
"""
ispayload(req::HTTP.Request) = req.method in [POST, PUT, PATCH]


"""
    ispayload(params::Genie.Context.Params)

True if the request can carry a payload - that is, it's a `POST`, `PUT`, or `PATCH` request
"""
ispayload(params::Genie.Context.Params) = ispayload(params[:request])


"""
    route_request(req::Request, res::Response) :: Response

First step in handling a request: sets up params collection, handles query vars, negotiates content.
"""
function route_request(req::HTTP.Request, res::HTTP.Response) :: HTTP.Response
  params = Params(req, res)

  for f in unique(content_negotiation_hooks)
    try
      req, res, params = f(req, res, params)
    catch ex
      @error ex
      Genie.Configuration.isdev() && rethrow(ex)

      if isa(ex, Genie.Exceptions.ExceptionalResponse)
        return ex.response
      end
    end
  end

  if is_static_file(req.target) && req.method === GET
    if isroute(baptizer(req.target, [lowercase(req.method)]))
      @warn "Route matches static file: $(req.target) -- executing route"
    elseif Genie.config.server_handle_static_files
      return serve_static_file(req.target)
    else
      return error(req.target, response_mime(params), Val(404))
    end
  end

  Genie.Configuration.isdev() && Revise.revise()

  for f in unique(pre_match_hooks)
    try
      req, res, params = f(req, res, params)
    catch ex
      @error ex
      Genie.Configuration.isdev() && rethrow(ex)

      if isa(ex, Genie.Exceptions.ExceptionalResponse)
        return ex.response
      end
    end
  end

  matched_route = match_routes(req, res, params)

  res = matched_route === nothing ?
    error(req.target, response_mime(params), Val(404)) :
      run_route(params, matched_route)

  if res.status === 404 && req.method === OPTIONS
    res = preflight_response()

    log_response(req, res)

    return res
  end

  for f in unique(pre_response_hooks)
    try
      req, res, params = f(req, res, params)
    catch ex
      @error ex
      Genie.Configuration.isdev() && rethrow(ex)

      if isa(ex, Genie.Exceptions.ExceptionalResponse)
        return ex.response
      end
    end
  end

  log_response(req, res)

  req.method == HEAD && (res.body = UInt8[])

  res
end


function log_response(req::HTTP.Request, res::HTTP.Response) :: Nothing
  if Genie.config.log_requests
    reqstatus = "$(req.method) $(req.target) $(res.status)\n"

    if res.status < 400
      @info reqstatus
    else
      @error reqstatus
    end
  end

  nothing
end


"""
    route_ws_request(req::Request, msg::String, ws_client::HTTP.WebSockets.WebSocket) :: String

First step in handling a web socket request: sets up params collection, handles query vars.
"""
function route_ws_request(req, msg::Union{String,Vector{UInt8}}, ws_client) :: String
  params = Params(req, req.response)

  params.collection = ImmutableDict(
    params.collection,
    :wsclient => ws_client
  )

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
  Route(method = method, path = path, action = action, name = named, context = context) |> route
end
function route(r::Route) :: Route
  r.name === nothing && (r.name = routename(r))

  Router.push!(_routes, r.name, r)
end
function routes(args...; method::Vector{<:AbstractString}, kwargs...)
  for m in method
    route(args...; method = m, kwargs...)
  end
end


macro route(expr...)
  path, action, method, named, context = nothing, nothing, GET, nothing, __module__

  if length(expr) == 1 && isa(expr[1], Tuple)
    expr = expr[1]
  end

  process_kw(ex) = begin
    if ex.args[1] == :method
      method = ex.args[2]
    elseif ex.args[1] == :named
      named = ex.args[2]
    end
  end

  for (idx,ex) in enumerate(expr)
    if typeof(ex) === Expr

      if ex.head == :kw
        process_kw(ex)
        continue
      elseif ex.head == :(=)
        process_kw(ex)
      elseif ex.head == :parameters
        for (idx,ex) in enumerate(ex.args)
          if typeof(ex) === Expr
            if ex.head == :kw
              process_kw(ex)
              continue
            end
          end
        end
      end

    end

    typeof(ex) === String && (path = ex)
    typeof(ex) === Symbol && (action = ex)
    typeof(ex) === Expr && (action = ex)
  end

  quote
    (() -> route($action, $path; method = $method, named = $named, context = $context))()
  end |> esc
end


macro get(expr...)
  expr = tuple(:(method = GET), expr...)
  :((@__MODULE__).@route($expr)) |> esc
end
macro post(expr...)
  expr = tuple(:(method = POST), expr...)
  :((@__MODULE__).@route($expr)) |> esc
end
macro put(expr...)
  expr = tuple(:(method = PUT), expr...)
  :((@__MODULE__).@route($expr)) |> esc
end
macro patch(expr...)
  expr = tuple(:(method = PATCH), expr...)
  :((@__MODULE__).@route($expr)) |> esc
end
macro delete(expr...)
  expr = tuple(:(method = DELETE), expr...)
  :((@__MODULE__).@route($expr)) |> esc
end
macro options(expr...)
  expr = tuple(:(method = OPTIONS), expr...)
  :((@__MODULE__).@route($expr)) |> esc
end
macro head(expr...)
  expr = tuple(:(method = HEAD), expr...)
  :((@__MODULE__).@route($expr)) |> esc
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
    routename(route) :: Symbol

Computes the name of a route.
"""
function routename(route::Route) :: Symbol
  baptizer(route, String[lowercase(route.method)])
end


"""
    channelname(channel) :: Symbol

Computes the name of a channel.
"""
function channelname(channel::Channel) :: Symbol
  baptizer(channel, String[])
end


"""
    baptizer(params::Union{Route,Channel}, parts::Vector{String}) :: Symbol

Generates default names for routes and channels.
"""
function baptizer(route_path::String, parts::Vector{String} = String[]) :: Symbol
  for uri_part in split(route_path, '/', keepempty = false)
    startswith(uri_part, ":") ?
      push!(parts, "by", lowercase(uri_part)[2:end]) :
        push!(parts, lowercase(uri_part))

  end

  join(parts, "_") |> Symbol
end
function baptizer(params::Union{Route,Channel}, parts::Vector{String} = String[]) :: Symbol
  baptizer(params.path, parts)
end


"""
The list of the defined named routes.
"""
function named_routes() :: OrderedCollections.LittleDict{Symbol,Route}
  _routes
end
const namedroutes = named_routes


function ischannel(channel_name::Symbol) :: Bool
  haskey(named_channels(), channel_name)
end


"""
    named_channels() :: Dict{Symbol,Any}

The list of the defined named channels.
"""
function named_channels() :: OrderedCollections.LittleDict{Symbol,Channel}
  _channels
end
const namedchannels = named_channels


function isroute(route_name::Symbol) :: Bool
  haskey(named_routes(), route_name)
end


"""
Gets the `Route` corresponding to `routename`
"""
function get_route(route_name::Symbol; default::Union{Route,Nothing} = Route()) :: Route
  isroute(route_name) ?
    named_routes()[route_name] :
    (if default === nothing
      Base.error("Route named `$route_name` is not defined")
    else
      Genie.Configuration.isdev() && @debug "Route named `$route_name` is not defined"

      default
    end)
end
const getroute = get_route


"""
    routes() :: Vector{Route}

Returns a vector of defined routes.
"""
function routes(; reversed::Bool = true) :: Vector{Route}
  collect(values(_routes)) |> (reversed ? reverse : identity)
end


"""
    channels() :: Vector{Channel}

Returns a vector of defined channels.
"""
function channels() :: Vector{Channel}
  collect(values(_channels)) |> reverse
end


"""
    delete!(route_name::Symbol)

Removes the route with the corresponding name from the routes collection and returns the collection of remaining routes.
"""
function delete!(key::Symbol) :: Vector{Route}
  OrderedCollections.delete!(_routes, key)
  return routes()
end


"""
Generates the HTTP link corresponding to `route_name` using the parameters in `d`.
"""
function to_url(  route_name::Symbol,
                  d::OrderedCollections.LittleDict;
                  params::Genie.Context.Params = Genie.Context.Params(),
                  basepath::String = basepath,
                  preserve_query::Bool = true,
                  extra_query::OrderedCollections.LittleDict = OrderedCollections.LittleDict())::String
  route = get_route(route_name)

  newpath = isempty(basepath) ? route.path : basepath * route.path

  result = String[]
  for part in split(newpath, '/')
    if occursin("#", part)
      part = split(part, "#")[1] |> string
    end

    if startswith(part, ":")
      var_name = split(part, "::")[1][2:end] |> Symbol
      ( isempty(d) || ! haskey(d, var_name) ) && Base.error("Route $route_name expects param $var_name")
      push!(result, pathify(d[var_name]))
      Base.delete!(d, var_name)

      continue
    end

    push!(result, part)
  end

  query_vars = preserve_query ? query(params[:request].target) : OrderedCollections.LittleDict()

  for (k,v) in extra_query
    query_vars[string(k)] = string(v)
  end

  qv = String[]
  for (k,v) in query_vars
    push!(qv, "$k=$v")
  end

  join(result, '/') * ( ! isempty(qv) ? '?' : "" ) * join(qv, '&')
end


function query(url::String) :: OrderedCollections.LittleDict
  query = HTTP.URIs.URI(url).query
  isempty(query) && return OrderedCollections.LittleDict()

  query_vars = OrderedCollections.LittleDict()
  for pair in split(query, '&')
    try
      parts = split(pair, '=')
      query_vars[parts[1]] = parts[2]
    catch ex
      # @error ex
    end
  end

  query_vars
end


"""
Generates the HTTP link corresponding to `route_name` using the parameters in `route_params`.
"""
function to_url(  route_name::Symbol;
                  params::Genie.Context.Params = Genie.Context.Params(),
                  basepath::String = Genie.config.base_path,
                  preserve_query::Bool = true,
                  extra_query::OrderedCollections.LittleDict = OrderedCollections.LittleDict(),
                  route_params...) :: String
  to_url(route_name, route_params_to_dict(route_params); params, basepath, preserve_query, extra_query)
end


"""
    route_params_to_dict(route_params)

Converts the route params to a `Dict`.
"""
function route_params_to_dict(route_params) :: OrderedCollections.LittleDict
  OrderedCollections.LittleDict(route_params)
end


"""
    action_controller_params(action::Function, params::Params) :: Nothing

Sets up the :action_controller, :action, and :controller key - value pairs of the `params` collection.
"""
function action_controller_params(action::Function, params::Genie.Context.Params)
  params.collection = ImmutableDict(
    params.collection,
    :action => action,
    :controller => (action |> typeof).name.module
  )

  params
end


"""
    match_routes(req::Request, res::Response, params::Params) :: Union{Route,Nothing}

Matches the invoked URL to the corresponding route, sets up the execution environment and invokes the controller method.
"""
function match_routes(req::HTTP.Request, res::HTTP.Response, params::Genie.Context.Params) :: Union{Route,Nothing}
  endswith(req.target, "/") && req.target != "/" && (req.target = req.target[1:end-1])
  uri = HTTP.URIs.URI(HTTP.URIs.unescapeuri(req.target))

  for r in routes()
    # method must match but we can also handle HEAD requests with GET routes
    (r.method == req.method) || (r.method == GET && req.method == HEAD) || continue

    parsed_route, param_names, param_types = Genie.Configuration.isprod() ?
                                              get!(ROUTE_CACHE, r.path, parse_route(r.path, context = r.context)) :
                                                parse_route(r.path, context = r.context)

    regex_route = try
      Regex("^" * parsed_route * "\$")
    catch
      @error "Invalid route $parsed_route"

      continue
    end

    ROUTE_CATCH_ALL = "/*"
    occursin(regex_route, string(uri.path)) || parsed_route == ROUTE_CATCH_ALL || continue

    params = Genie.Context.setup_base_params(req, res, params)

    occursin("?", req.target) && (params = extract_get_params(HTTP.URIs.URI(req.target), params))

    params = extract_uri_params(uri.path |> string, regex_route, param_names, param_types, params)

    ispayload(req) && (params = extract_post_params(params))
    ispayload(req) && (params = extract_request_params(params))
    params = action_controller_params(r.action, params)

    params.collection = ImmutableDict(
      params.collection,
      :route => r,
      :mime => MIME(request_type(req))
    )

    for f in unique(content_negotiation_hooks)
      try
        req, res, params = f(req, res, params)
      catch ex
        @error ex
        Genie.Configuration.isdev() && rethrow(ex)

        if isa(ex, Genie.Exceptions.ExceptionalResponse)
          return ex.response
        end
      end
    end

    return r
  end

  nothing
end


function run_route(params::Genie.Context.Params, r::Route) :: HTTP.Response
  try
    # prefer the method that takes params
    for m in methods(r.action)
      if m.sig.parameters |> length === 2
        try
          return r.action(params) |> to_response
        catch ex
          if isa(ex, MethodError) && string(ex.f) == string(r.action)
            return Base.invokelatest(r.action, params) |> to_response
          else
            rethrow(ex)
          end
        end
      end
    end

    # fallback to the method that does not take params
    for m in methods(r.action)
      if m.sig.parameters |> length === 1
        try
          return r.action() |> to_response
        catch ex
          if isa(ex, MethodError) && string(ex.f) == string(r.action)
            return Base.invokelatest(r.action) |> to_response
          else
            rethrow(ex)
          end
        end
      end
    end

    Base.error("No matching method found for route $(r.path)")
  catch ex
    return handle_exception(params, ex)
  end
end


function handle_exception(_::Genie.Context.Params, ex::Genie.Exceptions.ExceptionalResponse)
  ex.response
end

function handle_exception(_::Genie.Context.Params, ex::Genie.Exceptions.RuntimeException)
  rethrow(ex)
end

function handle_exception(params::Genie.Context.Params, ex::Genie.Exceptions.InternalServerException)
  error(ex.message, response_mime(params[:request]), Val(500))
end

function handle_exception(params::Genie.Context.Params, ex::Genie.Exceptions.NotFoundException)
  error(ex.resource, response_mime(params[:request]), Val(404))
end

function handle_exception(_::Genie.Context.Params, ex::Exception)
  rethrow(ex)
end

function handle_exception(_::Genie.Context.Params, ex::Any)
  Base.error(ex |> string)
end


"""
    match_channels(req::Request, msg::String, ws_client::HTTP.WebSockets.WebSocket, params::Params) :: String

Matches the invoked URL to the corresponding channel, sets up the execution environment and invokes the channel controller method.
"""
function match_channels(req, msg::String, ws_client, params::Genie.Context.Params) :: String
  payload::ImmutableDict{String,Any} = try
    JSON3.read(msg, ImmutableDict{String,Any})
  catch ex
    OrderedCollections.LittleDict{String,Any}()
  end

  uri = haskey(payload, "channel") ? '/' * payload["channel"] : '/'
  uri = haskey(payload, "message") ? uri * '/' * payload["message"] : uri
  uri = string(uri)

  for c in channels()
    parsed_channel, param_names, param_types = parse_channel(c.path)

    haskey(payload, "payload") && (params.collection = ImmutableDict(params.collection, :payload => payload["payload"]))

    regex_channel = Regex("^" * parsed_channel * "\$")

    (! occursin(regex_channel, uri)) && continue

    params = setup_base_params(req, nothing, params)

    extract_uri_params(uri, regex_channel, param_names, param_types, params) || continue

    action_controller_params(c.action, params)

    params.collection = ImmutableDict(
      params.collection,
      :channel => c
    )

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

  if occursin('#', route) || occursin(':', route) || occursin('*', route)
    validation_match = "[\\w\\-\\.\\+\\,\\s\\%\\:\\(\\)\\[\\]]+"

    for rp in split(route, '/', keepempty = false)
      if occursin("#", rp)
        x = split(rp, "#")
        rp = x[1] |> string
        validation_match = x[2]
      end

      if rp == "*"
        push!(parts, "(?P<_>(.*))")
        push!(param_names, "_")
        push!(param_types, Any)

        continue
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
function extract_uri_params(uri::T, regex_route::Regex, param_names::Vector{T}, param_types::Vector{Any},
                            params::Genie.Context.Params) where T<:AbstractString
  matches = match(regex_route, uri)

  i = 1
  for param_name in param_names
    try
      params.collection = ImmutableDict(
        params.collection,
        Symbol(param_name) => parse_param(param_types[i], matches[param_name])
      )
    catch ex
      @error ex
    end

    i += 1
  end

  params
end


"""
    extract_get_params(uri::URI, params::Params)

Extracts query vars and adds them to the execution `params` `Dict`.
"""
function extract_get_params(uri::HTTP.URIs.URI, params::Genie.Context.Params)
  if ! isempty(uri.query)
    if occursin("%5B%5D", uri.query) || occursin("[]", uri.query) # array values []
      for query_part in split(uri.query, "&")
        qp = split(query_part, "=")
        (size(qp)[1] == 1) && (push!(qp, ""))

        k = Symbol(HTTP.URIs.unescapeuri(qp[1]))
        v = HTTP.URIs.unescapeuri(qp[2])

        # collect values like x[] in an array
        if endswith(string(k), "[]")
          (haskey(params[:query], k) && isa(params[:query][k], Vector)) || (params[:query][k] = String[])
          push!(params[:query][k], v)
        else
          params[:query][k] = v
        end
      end

    else # no array values
      for (k,v) in HTTP.URIs.queryparams(uri)
        k = Symbol(k)
        params[:query][k] = v
      end
    end
  end

  params
end


"""
    extract_post_params(params::Params) :: Nothing

Parses POST variables and adds the to the `params` `Dict`.
"""
function extract_post_params(params::Genie.Context.Params)
  try
    input = Genie.Input.all(params[:request])

    params.collection = ImmutableDict(
      params.collection,
      :post => OrderedCollections.LittleDict([(Symbol(k)=>v) for (k,v) in input.post]...),
      :files => input.files
    )
  catch ex
    @error ex
  end

  params
end


"""
    extract_request_params(req::HTTP.Request, params::Params)

Sets up the `params` key-value pairs corresponding to a JSON payload.
"""
function extract_request_params(params::Genie.Context.Params)
  req = params[:request]
  req_body = String(req.body)

  params.collection = ImmutableDict(
    params.collection,
    :raw => req_body
  )

  if request_type_is(req, :json) && content_length(req) > 0
    try
      params[:post][:json] = (params.collection = ImmutableDict(params.collection, :json => JSON3.read(req_body)))
    catch ex
      @error ex
    end
  end

  params
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
function content_length(params::Genie.Context.Params) :: Int
  content_length(params[:request])
end


"""
    request_type_is(req::HTTP.Request, request_type::Symbol) :: Bool

Checks if the request content-type is of a certain type.
"""
function request_type_is(req::HTTP.Request, reqtype::Symbol) :: Bool
  ! in(reqtype, keys(request_mappings()) |> collect) &&
    error("Unknown request type $reqtype - expected one of $(keys(request_mappings()) |> collect).")

  request_type(req) == reqtype
end
function request_type_is(params::Genie.Context.Params, reqtype::Symbol) :: Bool
  request_type_is(params[:request], reqtype)
end


"""
    request_type(req::HTTP.Request) :: Symbol

Gets the request's content type.
"""
function request_type(req::HTTP.Request) :: Symbol
  accepted_encodings = strip.(collect(Iterators.flatten(split.(strip.(split(content_type(req), ';')), ','))))

  for accepted_encoding in accepted_encodings
    for (k,v) in request_mappings()
      if in(accepted_encoding, v)
        return k
      end
    end
  end

  isempty(accepted_encodings[1]) ? Symbol(request_mappings()[:html]) : Symbol(accepted_encodings[1])
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
    function query

The collection containing the query request variables collection (GET params).
"""
function query(params::Genie.Context.Params)
  params[:query]
end
function query(params::Genie.Context.Params, key)
  query(params)[key]
end
function query(params::Genie.Context.Params, key, default)
  get(query(params), key, default)
end



"""
    function post

The collection containing the POST request variables collection.
"""
function post(params::Genie.Context.Params)
  params[:post]
end
function post(params::Genie.Context.Params, key)
  post(params)[key]
end
function post(params::Genie.Context.Params, key, default)
  get(post(params), key, default)
end


"""
    function request(params)

The request object.
"""
function request(params::Genie.Context.Params) :: HTTP.Request
  params[:request]
end


"""
    function headers(params)

The current request's headers (as a Dict)
"""
function headers(params::Genie.Context.Params)::OrderedCollections.LittleDict
  OrderedCollections.LittleDict(request(params).headers)
end


"""
    response_type{T}(params::Dict{Symbol,T}) :: Symbol
    response_type(params::Params) :: Symbol

Returns the content-type of the current request-response cycle.
"""
function response_type(params_collection::ImmutableDict{Symbol,T})::Symbol where {T}
  get(params_collection, :response_type, request_type(params_collection[:request]))
end
function response_type(params::Genie.Context.Params)::Symbol
  response_type(params.collection)
end


"""
    response_type{T}(check::Symbol, params::Dict{Symbol,T}) :: Bool

Checks if the content-type of the current request-response cycle matches `check`.
"""
function response_type(check::Symbol, params_collection::ImmutableDict{Symbol,T})::Bool where {T}
  check == response_type(params_collection)
end


const responsetype = response_type


"""
    append_to_routes_file(content::String) :: Nothing

Appends `content` to the app's route file.
"""
function append_to_routes_file(content::T)::Nothing where {T<:AbstractString}
  open(Genie.ROUTES_FILE_NAME, "a") do io
    write(io, "\n" * content)
  end

  nothing
end


"""
    is_static_file(resource::String) :: Bool

Checks if the requested resource is a static file.
"""
function is_static_file(resource::T)::Bool where {T<:AbstractString}
  isfile(file_path(HTTP.URIs.URI(resource).path |> string))
end


"""
    escape_resource_path(resource::String)

Cleans up paths to resources.
"""
function escape_resource_path(resource::T)::String where {T<:AbstractString}
  startswith(resource, '/') || return resource
  resource = resource[2:end]

  '/' * join(map(x -> HTTP.URIs.escapeuri(x), split(resource, '?')), '?')
end


"""
    is_accessible_resource(resource::String) :: Bool

Checks if the requested resource is within the public/ folder.
"""
function is_accessible_resource(resource::T; root = Genie.config.server_document_root)::Bool where {T<:AbstractString}
  startswith(abspath(resource), abspath(root)) # the file path includes the root path
end


function bundles_path() :: String
  joinpath(@__DIR__, "..", "files", "static") |> normpath |> abspath
end


"""
    serve_static_file(resource::String) :: Response
Reads the static file and returns the content as a `Response`.
"""
function serve_static_file(resource::T; root = Genie.config.server_document_root, download = false)::HTTP.Response where {T<:AbstractString}
  startswith(resource, '/') || (resource = "/$(resource)")
  resource_path = try
                    HTTP.URIs.URI(resource).path |> string
                  catch ex
                    resource
                  end

  f = file_path(resource_path; root = root)
  isempty(f) && (f = pwd() |> relpath)

  fileheader = file_headers(f)
  download && push!(fileheader, ("Content-Disposition" => """attachment; filename=$(basename(f))"""))

  if (isfile(f) || isdir(f)) && ! is_accessible_resource(f; root)
    @error "401 Unauthorised Access $f"
    return error(resource, "text/plain", Val(401))
  end

  if isfile(f)
    return HTTP.Response(200, fileheader, body = read(f, String))
  elseif isdir(f)
    for fn in ["index.html", "index.htm", "index.txt"]
      isfile(joinpath(f, fn)) && return serve_static_file(joinpath(f, fn), root = root)
    end
  else
    bundled_path = joinpath(bundles_path(), resource[2:end])

    if ! is_accessible_resource(bundled_path; root = bundles_path())
      @error "401 Unauthorised Access $f"
      return error(resource, "text/plain", Val(401))
    end

    if isfile(bundled_path)
      return HTTP.Response(200, file_headers(bundled_path), body = read(bundled_path, String))
    end
  end

  @error "404 Not Found $f [$(abspath(f))]"
  error(resource, response_mime(params[:request]), Val(404))
end


function serve_file(params::Genie.Context.Params, f::T)::HTTP.Response where {T<:AbstractString}
  fileheader = file_headers(f)
  if isfile(f)
    return HTTP.Response(200, fileheader, body = read(f, String))
  else
    @error "404 Not Found $f [$(abspath(f))]"
    error(f, response_mime(params[:request]), Val(404))
  end
end
function serve_file(f::T)::HTTP.Response where {T<:AbstractString}
  serve_file(f)
end


"""
    download(filepath::String; root) :: HTTP.Response
Download an existing file from the server.
"""
function download(params::Genie.Context.Params, filepath::T; root)::HTTP.Response where {T<:AbstractString}
  return serve_static_file(filepath; root=root, download=true)
end



"""
    download(data::Vector{UInt8}, filename::String, mimetype) :: HTTP.Response

Download file from generated stream of bytes
"""
function download(data::Vector{UInt8}, filename::T, mimetype::String)::HTTP.Response where {T<:AbstractString}
  if mimetype in values(MIMEs._ext2mime)
    return HTTP.Response(200,
        ("Content-Type" => mimetype, "Content-Disposition" => """attachment; filename=$(filename)"""),
        body=data)
  end

  error("415 Unsupported Media Type $mimetype")
end


"""
preflight_response() :: HTTP.Response

Sets up the preflight CORS response header.
"""
function preflight_response() :: HTTP.Response
  HTTP.Response(200, Genie.config.cors_headers, body = "Success")
end


"""
    response_mime(params)

Returns the MIME type of the response.
"""
function response_mime(params::Params)
  if params.collection[:mime] === nothing
    params.collection = ImmutableDict(
      params.collection,
      :mime => response_mime(params[:request])
    )
  end

  if isempty(params[:mime] |> string)
    params.collection = ImmutableDict(
      params.collection,
      :mime => request_type(params[:request])
    )
  end

  params[:mime]
end
function response_mime(req::HTTP.Request)
  request_type(req)
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


function error(error_message::String, mime::Any, ::Val{401}; error_info::String = "") :: HTTP.Response
  HTTP.Response(401, ["Content-Type" => string(trymime(mime))], body = "401 Unauthorised - $error_message. $error_info")
end


function error(error_message::String, mime::Any, ::Val{404}; error_info::String = "") :: HTTP.Response
  HTTP.Response(404, ["Content-Type" => string(trymime(mime))], body = "404 Not Found - $error_message. $error_info")
end


function error(error_code::Int, error_message::String, mime::Any; error_info::String = "") :: HTTP.Response
  HTTP.Response(error_code, ["Content-Type" => string(trymime(mime))], body = "$error_code Error - $error_message. $error_info")
end


"""
    file_path(resource::String; within_doc_root = true, root = Genie.config.server_document_root) :: String

Returns the path to a resource file. If `within_doc_root` it will automatically prepend the document root to `resource`.
"""
function file_path(resource::String; within_doc_root = true, root = Genie.config.server_document_root) :: String
  within_doc_root = (within_doc_root && root == Genie.config.server_document_root)
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
  ["Content-Type" => get(MIMEs._ext2mime, file_extension(f), "application/octet-stream")]
end


ormatch(r::RegexMatch, x) = r.match
ormatch(r::Nothing, x) = x

end
