module Router

using HttpServer, URIParser, Genie, AppServer, Memoize, Sessions
using Millboard, Configuration, App, Input, Logger, Util, Renderer, WebSockets, JSON
IS_IN_APP && @eval parse("@dependencies")

import HttpServer.mimetypes

include(joinpath(Pkg.dir("Genie"), "src", "router_converters.jl"))

export route, routes, channel, channels
export GET, POST, PUT, PATCH, DELETE
export to_link!!, to_link, link_to!!, link_to, response_type, @params

const GET     = "GET"
const POST    = "POST"
const PUT     = "PUT"
const PATCH   = "PATCH"
const DELETE  = "DELETE"

const BEFORE_ACTION_HOOKS = :before_action

const _routes = Dict{Symbol,Any}()
const _channels = Dict{Symbol,Any}()
const sessionless = Symbol[:json]

typealias Route Tuple{Tuple{String,String,Union{String,Function}},Dict{Symbol,Dict{Any,Any}}}
typealias Channel Tuple{Tuple{String,Union{String,Function}},Dict{Symbol,Dict{Any,Any}}}

type Params{T}
  collection::Dict{Symbol,T}
end
Params() = Params(Dict{Symbol,Any}())


"""
    response_type{T}(params::Dict{Symbol,T}) :: Symbol
    response_type(params::Params) :: Symbol

Returns the content-type of the current request-response cycle.
"""
function response_type{T}(params::Dict{Symbol,T}) :: Symbol
  haskey(params, :response_type) ? params[:response_type] : collect(keys(Renderer.CONTENT_TYPES))[1]
end
function response_type(params::Params) :: Symbol
  response_type(params.collection)
end


"""
    response_type{T}(check::Symbol, params::Dict{Symbol,T}) :: Bool

Checks if the content-type of the current request-response cycle matches `check`.
"""
function response_type{T}(check::Symbol, params::Dict{Symbol,T}) :: Bool
  check == response_type(params)
end


"""
    route_request(req::Request, res::Response, ip::IPv4 = ip"0.0.0.0") :: Response

First step in handling a request: sets up @params collection, handles query vars, negotiates content, starts and persists sessions.
"""
function route_request(req::Request, res::Response, ip::IPv4 = ip"0.0.0.0") :: Response
  params = Params()
  params.collection[:request_ipv4] = ip

  extract_get_params(URI(to_uri(req.resource)), params)
  res = negotiate_content(req, res, params)

  if is_static_file(req.resource)
    App.config.server_handle_static_files && return serve_static_file(req.resource)
    return serve_error_file(404, "File not found: $(req.resource)", params.collection)
  end

  if is_dev()
    load_routes()

    App.load_models()
    App.load_libs()
  end

  session = App.config.session_auto_start ? Sessions.start(req, res) : nothing

  controller_response::Response = match_routes(req, res, session, params)

  ! in(response_type(params), sessionless) && App.config.session_auto_start && Sessions.persist(session)

  print_with_color(:green, "[$(Dates.now())] -- $(URI(to_uri(req.resource))) -- Done\n\n")

  controller_response
end


"""
    route_ws_request(req::Request, msg::String, ws_client::WebSockets.WebSocket, ip::IPv4 = ip"0.0.0.0") :: String

First step in handling a web socket request: sets up @params collection, handles query vars, starts and persists sessions.
"""
function route_ws_request(req::Request, msg::String, ws_client::WebSockets.WebSocket, ip::IPv4 = ip"0.0.0.0") :: String
  params = Params()
  params.collection[:request_ipv4] = ip
  params.collection[Genie.PARAMS_WS_CLIENT] = ws_client

  extract_get_params(URI(req.resource), params)

  if is_dev()
    load_channels()
    App.load_models()
  end

  session = App.config.session_auto_start ? Sessions.load(Sessions.id(req)) : nothing

  channel_response::String = match_channels(req, msg, ws_client, params, session)

  print_with_color(:cyan, "[$(Dates.now())] -- $(URI(req.resource)) -- Done\n\n")

  channel_response
end


"""
    negotiate_content(req::Request, res::Response, params::Params) :: Response

Computes the content-type of the `Response`, based on the information in the `Request`.
"""
function negotiate_content(req::Request, res::Response, params::Params) :: Response
  function set_negotiated_content()
    params.collection[:response_type] = collect(keys(Renderer.CONTENT_TYPES))[1]
    res.headers["Content-Type"] = Renderer.CONTENT_TYPES[params.collection[:response_type]]

    true
  end

  if haskey(params.collection, :response_type) && in(Symbol(params.collection[:response_type]), collect(keys(Renderer.CONTENT_TYPES)) )
    params.collection[:response_type] = Symbol(params.collection[:response_type])
    res.headers["Content-Type"] = Renderer.CONTENT_TYPES[params.collection[:response_type]]

    return res
  end

  negotiation_header = haskey(req.headers, "Accept") ? "Accept" : ( haskey(req.headers, "Content-Type") ? "Content-Type" : "" )

  isempty(negotiation_header) && set_negotiated_content() && return res

  accept_parts = split(req.headers[negotiation_header], ";")

  isempty(accept_parts) && set_negotiated_content() && return res

  accept_order_parts = split(accept_parts[1], ",")

  isempty(accept_order_parts) && set_negotiated_content() && return res

  for mime in accept_order_parts
    if contains(mime, "/")
      content_type = split(mime, "/")[2] |> lowercase |> Symbol
      if haskey(Renderer.CONTENT_TYPES, content_type)
        params.collection[:response_type] = content_type
        res.headers["Content-Type"] = Renderer.CONTENT_TYPES[params.collection[:response_type]]

        return res
      end
    end
  end

  set_negotiated_content() && return res
end


"""
    route(action::Function, path::String; method = GET, with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_route) :: Route
    route(path::String, action::Union{String,Function}; method = GET, with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_route) :: Route
    route(path::String; resource::Union{String,Symbol} = "", controller::Union{String,Symbol} = "", action::Union{String,Symbol} = "",
                    method = GET, with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_route) :: Route

Used for defining Genie routes.
"""
function route(action::Function, path::String; method = GET, with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_route) :: Route
  route(path, action, method = method, with = with, named = named)
end
function route(path::String; resource::Union{String,Symbol} = "", controller::Union{String,Symbol} = "", action::Union{String,Symbol} = "",
                method = GET, with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_route) :: Route
  resource = string(resource)
  controller = string(controller)
  action = string(action)
  route(path, resource * "#" * (! isempty(controller) ? controller * "." : "") * action, method = method, with = with, named = named)
end
function route(path::String, action::Union{String,Function}; method = GET, with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_route) :: Route
  route_parts = (method, path, action)

  extra_route_parts = Dict(:with => with)
  named = named == :__anonymous_route ? route_name(route_parts) : named

  if Configuration.is_dev() && haskey(_routes, named)
    Logger.log(
      "Conflicting routes names - multiple routes are sharing the same name. Use the 'named' option to assign them different identifiers.\n" *
      string(_routes[named]) * "\n" *
      string(route_parts, extra_route_parts)
      , :warn)
  end

  _routes[named] = (route_parts, extra_route_parts)
end


"""
    channel(action::Function, path::String; with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_channel) :: Channel
    channel(path::String, action::Union{String,Function}; with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_channel) :: Channel

Used for defining Genie channels.
"""
function channel(action::Function, path::String; with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_channel) :: Channel
  channel(path, action, with = with, named = named)
end
function channel(path::String; resource::Union{String,Symbol} = "", controller::Union{String,Symbol} = "", action::Union{String,Symbol} = "",
                with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_route) :: Route
  resource = string(resource)
  controller = string(controller)
  action = string(action)
  route(path, resource * "#" * (! isempty(controller) ? controller * "." : "") * action, with = with, named = named)
end
function channel(path::String, action::Union{String,Function}; with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_channel) :: Channel
  channel_parts = (path, action)

  extra_channel_parts = Dict(:with => with)
  named = named == :__anonymous_channel ? channel_name(channel_parts) : named

  if Configuration.is_dev() && haskey(_channels, named)
    Logger.log(
      "Conflicting channel names - multiple channels are sharing the same name. Use the 'named' option to assign them different identifiers.\n" *
      string(_channels[named]) * "\n" *
      string(channel_parts, extra_channel_parts)
      , :warn)
  end

  _channels[named] = (channel_parts, extra_channel_parts)
end


"""
    route_name(params) :: Symbol

Computes the name of a route.
"""
function route_name(params) :: Symbol
  route_parts = String[lowercase(params[1])]
  for uri_part in split(params[2], "/", keep = false)
    startswith(uri_part, ":") && continue # we ignore named params
    push!(route_parts, lowercase(uri_part))
  end

  join(route_parts, "_") |> Symbol
end


"""
    channel_name(params) :: Symbol

Computes the name of a channel.
"""
function channel_name(params) :: Symbol
  channel_parts = String[lowercase(params[1])]
  for uri_part in split(params[2], "/", keep = false)
    startswith(uri_part, ":") && continue # we ignore named params
    push!(channel_parts, lowercase(uri_part))
  end

  join(channel_parts, "_") |> Symbol
end


"""
    named_routes() :: Dict{Symbol,Any}

The list of the defined named routes.
"""
function named_routes() :: Dict{Symbol,Any}
  _routes
end


"""
    print_named_routes() :: Void

Prints a table of the routes and their names to standard output.
"""
function print_named_routes() :: Void
  Millboard.table(named_routes()) |> println
end


"""
    get_route(route_name::Symbol) :: Nullable{Route}

Gets the `Route` correspoding to `route_name`, wrapped in a `Nullable`.
"""
function get_route(route_name::Symbol) :: Nullable{Route}
  haskey(named_routes(), route_name) ? Nullable(named_routes()[route_name]) : Nullable()
end


"""
    get_route!!(route_name::Symbol) :: Route

Gets the `Route` correspoding to `route_name` - errors if the route is not defined.
"""
function get_route!!(route_name::Symbol) :: Route
  get_route(route_name) |> Base.get
end


"""
    routes() :: Vector{Route}

Returns a vector of defined routes.
"""
function routes() :: Vector{Route}
  collect(values(_routes))
end


"""
    routes() :: Vector{Route}

Returns a vector of defined routes.
"""
function channels() :: Vector{Channel}
  collect(values(_channels))
end


"""
    print_routes() :: Void

Prints a table of the defined routes to standard output.
"""
function print_routes() :: Void
  Millboard.table(routes()) |> println
end


"""
    to_link!!{T}(route_name::Symbol, d::Vector{Pair{Symbol,T}}) :: String
    to_link!!{T}(route_name::Symbol, d::Pair{Symbol,T}) :: String
    to_link!!{T}(route_name::Symbol, d::Dict{Symbol,T}) :: String
    to_link!!(route_name::Symbol; route_params...) :: String

Generates the HTTP link corresponding to `route_name`.
"""
function to_link!!{T}(route_name::Symbol, d::Vector{Pair{Symbol,T}}) :: String
  to_link!!(route_name, Dict(d...))
end
function to_link!!{T}(route_name::Symbol, d::Pair{Symbol,T}) :: String
  to_link!!(route_name, Dict(d))
end
function to_link!!{T}(route_name::Symbol, d::Dict{Symbol,T}) :: String
  route = try
            get_route!!(route_name)
          catch ex
            Logger.log("Route not found", :err)
            Logger.log(string(ex), :err)
            Logger.log("$(@__FILE__):$(@__LINE__)", :err)

            rethrow(ex)
          end

  result = String[]
  for part in split(route[1][2], "/")
    if startswith(part, ":")
      var_name = split(part, "::")[1][2:end] |> Symbol
      ( isempty(d) || ! haskey(d, var_name) ) && error("Route $route_name expects param $var_name")
      push!(result, pathify(d[var_name]))
      delete!(d, var_name)
      continue
    end
    push!(result, part)
  end

  query_vars = String[]
  if haskey(d, :_preserve_query)
    delete!(d, :_preserve_query)
    query = URI(task_local_storage(:__params)[:REQUEST].resource).query
    query != "" && (query_vars = split(query , "&" ))
  end

  for (k,v) in d
    push!(query_vars, "$k=$v")
  end

  join(result, "/") * ( size(query_vars, 1) > 0 ? "?" : "" ) * join(query_vars, "&")
end
function to_link!!(route_name::Symbol; route_params...) :: String
  to_link!!(route_name, route_params_to_dict(route_params))
end

const link_to!! = to_link!!

function to_link(route_name::Symbol; route_params...) :: String
  try
    to_link!!(route_name, route_params_to_dict(route_params))
  catch ex
    Logger.log("Route not found", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    ""
  end
end

const link_to = to_link


"""
    route_params_to_dict(route_params)

Converts the route params to a `Dict`.
"""
function route_params_to_dict(route_params) :: Dict{Symbol,Any}
  Dict{Symbol,Any}(route_params)
end


"""
    match_routes(req::Request, res::Response, session::Sessions.Session, params::Params) :: Response

Matches the invoked URL to the corresponding route, sets up the execution environment and invokes the controller method.
"""
function match_routes(req::Request, res::Response, session::Union{Sessions.Session,Void}, params::Params) :: Response
  for r in routes()
    route_def, extra_params = r
    protocol, route, to = route_def

    protocol != req.method && (! haskey(params.collection, :_method) || ( haskey(params.collection, :_method) && params.collection[:_method] != protocol )) && continue

    App.config.log_router && Logger.log("Router: Checking against " * route)

    parsed_route, param_names, param_types = parse_route(route)

    uri = URI(to_uri(req.resource))
    regex_route = Regex("^" * parsed_route * "\$")

    (! ismatch(regex_route, uri.path)) && continue
    App.config.log_router && Logger.log("Router: Matched route " * uri.path)

    (! extract_uri_params(uri.path, regex_route, param_names, param_types, params)) && continue
    App.config.log_router && Logger.log("Router: Matched type of route " * uri.path)

    extract_post_params(req, params)
    extract_extra_params(extra_params, params)
    extract_pagination_params(params)

    res = negotiate_content(req, res, params)

    params.collection = setup_base_params(req, res, params.collection, session)

    task_local_storage(:__params, params.collection)

    return  try
              if isa(to, Function)
                to() |> to_response
              else
                invoke_controller(to, req, res, params.collection, session)
              end
            catch ex
              Logger.log("Failed invoking controller", :err)
              Logger.log(string(ex), :err)
              Logger.log("$(@__FILE__):$(@__LINE__)", :err)

              rethrow(ex)
            end
  end

  App.config.log_router && Logger.log("Router: No route matched - defaulting 404", :err)
  serve_error_file(404, "Not found", params.collection)
end


"""
    match_channels(req::Request, msg::String, ws_client::WebSockets.WebSocket, params::Params, session::Sessions.Session) :: String

Matches the invoked URL to the corresponding channel, sets up the execution environment and invokes the channel controller method.
"""
function match_channels(req::Request, msg::String, ws_client::WebSockets.WebSocket, params::Params, session::Union{Sessions.Session,Void}) :: String
  for c in channels()
    channel_def, extra_params = c
    channel, to = channel_def

    App.config.log_router && Logger.log("Channels: Checking against " * channel)

    parsed_channel, param_names, param_types = parse_channel(channel)

    payload::Dict{String,Any} = try
                                  JSON.parse(msg)
                                catch ex
                                  Dict{String,Any}()
                                end

    uri = haskey(payload, "channel") ? "/" * payload["channel"] : "/"
    uri = haskey(payload, "message") ? uri * "/" * payload["message"] : uri

    haskey(payload, "payload") && (params.collection[:payload] = payload["payload"])

    regex_channel = Regex("^" * parsed_channel * "\$")

    (! ismatch(regex_channel, uri)) && continue
    App.config.log_router && Logger.log("Channels: Matched channel " * uri)

    (! extract_uri_params(uri, regex_channel, param_names, param_types, params)) && continue
    App.config.log_router && Logger.log("Router: Matched type of channel " * uri)

    extract_extra_params(extra_params, params)

    params.collection = setup_base_params(req, nothing, params.collection, session)

    task_local_storage(:__params, params.collection)

    return  try
              if isa(to, Function)
                to() |> string
              else
                invoke_channel(to, req, payload, ws_client, params.collection, session)
              end
            catch ex
              if is_dev()
                rethrow(ex)
              else
                Logger.log("Failed invoking channel", :err)
                Logger.log(string(ex), :err)
                Logger.log("$(@__FILE__):$(@__LINE__)", :err)

                string(ex)
              end
            end
  end

  App.log_router && Logger.log("Channel: No route matched - defaulting 404", :err)
  string("404 - Not found")
end


"""
    parse_route(route::String) :: Tuple{String,Vector{String},Vector{Any}}

Parses a route and extracts its named parms and types.
"""
function parse_route(route::String) :: Tuple{String,Vector{String},Vector{Any}}
  parts = AbstractString[]
  param_names = AbstractString[]
  param_types = Any[]

  for rp in split(route, "/", keep = false)
    if startswith(rp, ":")
      param_type =  if contains(rp, "::")
                      x = split(rp, "::")
                      rp = x[1]
                      getfield(current_module(), Symbol(x[2]))
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
    parse_channel(channel::String) :: Tuple{String,Vector{String},Vector{Any}}

Parses a channel and extracts its named parms and types.
"""
function parse_channel(channel::String) :: Tuple{String,Vector{String},Vector{Any}}
  parts = AbstractString[]
  param_names = AbstractString[]
  param_types = Any[]

  for rp in split(channel, "/", keep = false)
    if startswith(rp, ":")
      param_type =  if contains(rp, "::")
                      x = split(rp, "::")
                      rp = x[1]
                      getfield(current_module(), Symbol(x[2]))
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
      Logger.log("Failed to match URI params between $(param_types[i])::$(typeof(param_types[i])) and $(matches[param_name])::$(typeof(matches[param_name]))", :err)
      Logger.log(string(ex), :err)
      Logger.log("$(@__FILE__):$(@__LINE__)", :err)

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
      params.collection[Symbol(URIParser.unescape(qp[1]))] = URIParser.unescape(qp[2])
    end
  end

  true # this must be bool cause it's used in bool context for chaining
end


"""
    extract_extra_params(extra_params::Dict, params::Params) :: Void

Parses extra params present in the route's definition and sets them into the `params` `Dict`.
"""
function extract_extra_params(extra_params::Dict, params::Params) :: Void
  if ! isempty(extra_params[:with])
    for (k, v) in extra_params[:with]
      params.collection[Symbol(k)] = v
    end
  end

  nothing
end


"""
    extract_post_params(req::Request, params::Params) :: Void

Parses POST variables and adds the to the `params` `Dict`.
"""
function extract_post_params(req::Request, params::Params) :: Void
  for (k, v) in Input.post(req)
    v = replace(v, "+", " ")
    nested_keys(k, v, params)
    params.collection[Symbol(k)] = v
  end

  nothing
end


"""
    nested_keys(k::String, v, params::Params) :: Void

Utility function to process nested keys and set them up in `params`.
"""
function nested_keys(k::String, v, params::Params) :: Void
  if contains(k, ".")
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
    extract_pagination_params(params::Params) :: Void

Parses special query params using for pagination.
"""
function extract_pagination_params(params::Params) :: Void
  if ! haskey(params.collection, :page_number)
    params.collection[:page_number] = haskey(params.collection, Symbol("page[number]")) ? parse(Int, params.collection[Symbol("page[number]")]) : 1
  end
  if ! haskey(params.collection, :page_size)
    params.collection[:page_size] = haskey(params.collection, Symbol("page[size]")) ? parse(Int, params.collection[Symbol("page[size]")]) : App.config.pagination_default_items_per_page
  end

  nothing
end


"""
    setup_base_params(req::Request, res::Response, params::Dict{Symbol,Any}, session::Sessions.Session) :: Dict{Symbol,Any}

Populates `params` with default environment vars.
"""
function setup_base_params(req::Request, res::Union{Response,Void}, params::Dict{Symbol,Any}, session::Union{Sessions.Session,Void}) :: Dict{Symbol,Any}
  params[Genie.PARAMS_REQUEST_KEY]   = req
  params[Genie.PARAMS_RESPONSE_KEY]  = res
  params[Genie.PARAMS_SESSION_KEY]   = session
  params[Genie.PARAMS_FLASH_KEY]     = App.config.session_auto_start ?
                                       begin
                                        s = Sessions.get(session, Genie.PARAMS_FLASH_KEY)
                                        if isnull(s)
                                          ""
                                        else
                                          ss = Base.get(s)
                                          Sessions.unset!(session, Genie.PARAMS_FLASH_KEY)
                                          ss
                                        end
                                       end : ""

  params
end


"""
    setup_params!(params::Dict{Symbol,Any}, to_parts::Vector{String}, action_controller_parts::Vector{String}) :: Dict{Symbol,Any}

Populates `params` with action and controller names values.
"""
function setup_params!(params::Dict{Symbol,Any}, to_parts::Vector{String}, action_controller_parts::Vector{String}) :: Dict{Symbol,Any}
  params[:action_controller] = to_parts[2]
  params[:action] = action_controller_parts[end]
  params[:controller] = join(action_controller_parts[1:end-1], ".")

  params
end


const loaded_controllers = UInt64[]


"""
    invoke_controller(to::String, req::Request, res::Response, params::Dict{Symbol,Any}, session::Sessions.Session) :: Response

Invokes the designated controller method.
"""
function invoke_controller(to::String, req::Request, res::Response, params::Dict{Symbol,Any}, session::Union{Sessions.Session,Void}) :: Response
  to_parts::Vector{String} = split(to, "#")

  controller_path = abspath(joinpath(Genie.RESOURCES_PATH, to_parts[1]))
  controller_path_hash = hash(controller_path)
  if ! in(controller_path_hash, loaded_controllers) || Configuration.is_dev()
    App.load_controller(controller_path)
    App.export_controllers(to_parts[2])
    ! in(controller_path_hash, loaded_controllers) && push!(loaded_controllers, controller_path_hash)
  end

  controller = Genie.GenieController()
  action_name = to_parts[2]

  action_controller_parts::Vector{String} = split(to_parts[2], ".")
  setup_params!(params, to_parts, action_controller_parts)

  try
    params[Genie.PARAMS_ACL_KEY] = App.load_acl(controller_path)
  catch ex
      Logger.log("Failed loading ACL", :err)
      Logger.log(string(ex), :err)
      Logger.log("$(@__FILE__):$(@__LINE__)", :err)

      rethrow(ex)
  end

  task_local_storage(:__params, params)

  try
    hook_result = run_hooks(BEFORE_ACTION_HOOKS, get_deepest_module(action_name, 1, App), params)
    hook_stop(hook_result) && return to_response(hook_result[2])
  catch ex
    Logger.log("Failed to invoke hooks $(BEFORE_ACTION_HOOKS)", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end

  try
    App.config.log_requests && Logger.log("Invoking $action_name with params: \n" * string(Millboard.table(params)), :debug)
  catch ex
    Logger.log("Can't log request", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)
  end

  return  try
            (get_nested_field(action_name, 1, App).field)() |> to_response
          catch ex
            Logger.log("Error while invoking $(action_name) with $(params)", :err)
            Logger.log(string(ex), :err)
            Logger.log("$ex at $(@__FILE__):$(@__LINE__)", :err)

            rethrow(ex)
          end
end


const loaded_channels = UInt64[]


"""
    invoke_channel(to::String, req::Request, payload::Dict{String,Any}, ws_client::WebSockets.WebSocket, params::Dict{Symbol,Any}, session::Sessions.Session) :: String

Invokes the designated channel method.
"""
function invoke_channel(to::String, req::Request, payload::Dict{String,Any}, ws_client::WebSockets.WebSocket, params::Dict{Symbol,Any}, session::Union{Sessions.Session,Void}) :: String
  to_parts::Vector{String} = split(to, "#")

  channel_path = abspath(joinpath(Genie.RESOURCES_PATH, to_parts[1]))
  channel_path_hash = hash(channel_path)
  if ! in(channel_path_hash, loaded_channels) || Configuration.is_dev()
    App.load_channel(channel_path)
    App.export_channels(to_parts[2])
    ! in(channel_path_hash, loaded_channels) && push!(loaded_channels, channel_path_hash)
  end

  controller = Genie.GenieChannel()
  action_name = to_parts[2]

  action_channel_parts::Vector{String} = split(to_parts[2], ".")
  setup_params!(params, to_parts, action_channel_parts)

  try
    params[Genie.PARAMS_ACL_KEY] = App.load_acl(channel_path)
  catch ex
    if Configuration.is_dev()
      rethrow(ex)
    else
      Logger.log("Failed loading ACL", :err)
      Logger.log(string(ex), :err)
      Logger.log("$(@__FILE__):$(@__LINE__)", :err)

      return "500 error -- $(string(ex))"
    end
  end

  task_local_storage(:__params, params)

  try
    hook_result = run_hooks(BEFORE_ACTION_HOOKS, getfield(App, Symbol(join(split(action_name, ".")[1:end-1], "."))), params)
    hook_stop(hook_result) && return string(hook_result[2])
  catch ex
    if Configuration.is_dev()
      rethrow(ex)
    else
      Logger.log("Failed to invoke channel hooks $(BEFORE_ACTION_HOOKS)", :err)
      Logger.log(string(ex), :err)
      Logger.log("$(@__FILE__):$(@__LINE__)", :err)

      return "500 error -- $(string(ex))"
    end
  end

  App.config.log_requests && Logger.log("Invoking channel $action_name with params: \n" * string(Millboard.table(params)), :debug)

  return  try
            # TODO: add support for arbitrarely nested modules
            # getfield( getfield( getfield(current_module(), Symbol("App")), Symbol(split(action_name, ".")[1])), Symbol(split(action_name, ".")[2]))() |> string
            (get_nested_field(action_name, 1, App).field)() |> string
          catch ex
            if Configuration.is_dev()
              rethrow(ex)
            else
              Logger.log("$ex at $(@__FILE__):$(@__LINE__)", :err)
              Logger.log("While invoking $(action_name) with $(params)", :err)
              Logger.log("$(@__FILE__):$(@__LINE__)", :err)

              return "500 error -- $(string(ex))"
            end
          end
end


"""
    to_response(action_result) :: Response

Converts the result of invoking the controller action to a `Response`.
"""
function to_response(action_result) :: Response
  isa(action_result, Response) && return action_result

  return  try
            if isa(action_result, Tuple)
              Response(action_result...)
            else
              Response(action_result)
            end
          catch ex
            Logger.log("Can't convert $action_result to HttpServer.Response", :err)
            Logger.log(string(ex), :err)
            Logger.log("$(@__FILE__):$(@__LINE__)", :err)

            rethrow(ex)
          end
end


macro params()
  :(task_local_storage(:__params))
end
macro params(key::Expr)
  :(task_local_storage(:__params)[$key])
end
function _params_()
  task_local_storage(:__params)
end
function _params_(key::Union{String,Symbol})
  task_local_storage(:__params)[$key]
end


"""
    serve_error_file_500(ex::Exception, params::Dict{Symbol,Any} = Dict{Symbol,Any}()) :: Response

Returns the default 500 error page.
"""
function serve_error_file_500(ex::Exception, params::Dict{Symbol,Any} = Dict{Symbol,Any}()) :: Response
  serve_error_file( 500,
                    string(ex) *
                    "<br/><br/>" *
                    join(catch_stacktrace(), "<br/>") *
                    "<hr/>" *
                    string(params)
                  )
end


"""
    hook_stop(hook_result) :: Bool

Checks whether or not the hook's invokation caused an error and execution must be stopped.
"""
function hook_stop(hook_result) :: Bool
  isa(hook_result, Tuple) && ! hook_result[1]
end


"""
    run_hooks(hook_type::Symbol, m::Module, params::Dict{Symbol,Any}) :: Any

Runs the hooks defined in the currently invoked controller.
"""
function run_hooks(hook_type::Symbol, m::Module, params::Dict{Symbol,Any}) :: Tuple{Bool,Any}
  if in(hook_type, names(m, true))
    hooks::Vector{Symbol} = getfield(m, hook_type)
    for hook in hooks
      # r = eval(App, parse(string(hook)))()
      c, a = split(string(hook), ".")
      r = getfield(getfield(App, Symbol(c)), Symbol(a))()
      hook_stop(r) && return r
    end
  else
    tuple(true, nothing)
  end
end


"""
    routes_available() :: Bool

Checkes if the routes file is available.
"""
function routes_available() :: Bool
  ! IS_IN_APP && return false
  ! isfile(Genie.ROUTES_FILE_NAME) && return false

  true
end


"""
    load_routes() :: Void

Loads the routes file.
"""
function load_routes() :: Void
  ! routes_available() && return nothing

  empty!(_routes)
  include(Genie.ROUTES_FILE_NAME)

  nothing
end


"""
    append_to_routes_file(content::String) :: Void

Appends `content` to the app's route file.
"""
function append_to_routes_file(content::String) :: Void
  open(Genie.ROUTES_FILE_NAME, "a") do io
    write(io, "\n" * content)
  end

  nothing
end


"""
    load_channels() :: Void

Loads the routes file.
"""
function load_channels() :: Void
  ! IS_IN_APP && return nothing
  ! isfile(abspath(joinpath("config", "channels.jl"))) && return nothing

  empty!(_channels)
  include(abspath(joinpath("config", "channels.jl")))

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
    escaped_resource = join(map( x -> ( startswith(x, "/") ? escape_resource_path(x) : URIParser.escape(x) ) * "=" * URIParser.escape(URIParser.query_params(resource)[x]), qp ), "&")

    URI(escaped_resource)
  end
end


function escape_resource_path(resource::String)
  startswith(resource, "/") || return resource
  resource = resource[2:end]

  "/" * join(map(x -> URIParser.escape(x), split(resource, "?")), "?")
end


"""
    serve_static_file(resource::String) :: Response

Reads the static file and returns the content as a `Response`.
"""
function serve_static_file(resource::String) :: Response
  resource_path = try
                    URI(resource).path
                  catch ex
                    resource
                  end
  f = file_path(resource_path)

  if isfile(f)
    Response(200, file_headers(f), open(read, f))
  else
    Renderer.error_404() |> to_response
  end
end


"""
    serve_error_file(error_code::Int, error_message::String = "", params::Dict{Symbol,Any} = Dict{Symbol,Any}()) :: Response

Serves the error file correspoding to `error_code` and current environment.
"""
function serve_error_file(error_code::Int, error_message::String = "", params::Dict{Symbol,Any} = Dict{Symbol,Any}()) :: Response
  if Configuration.is_dev()
    error_page =  open(Genie.DOC_ROOT_PATH * "/error-$(error_code).html") do f
                    readstring(f)
                  end
    error_page = replace(error_page, "<error_message/>", error_message)
    Response(error_code, Dict{AbstractString,AbstractString}(), error_page)
  else
    f = file_path(URI("/error-$(error_code).html").path)
    Response(error_code, file_headers(f), open(read, f))
  end
end


"""
    file_path(resource::String; within_doc_root = true) :: String

Returns the path to a resource file. If `within_doc_root` it will automatically prepend the document root to `resource`.
"""
function file_path(resource::String; within_doc_root = true) :: String
  abspath(joinpath(within_doc_root ? App.config.server_document_root : "", resource[(startswith(resource, "/") ? 2 : 1):end]))
end


"""
    pathify(x) :: String

Returns a proper URI path from a string `x`.
"""
pathify(x) :: String = replace(string(x), " ", "-") |> lowercase |> URIParser.escape


"""
    file_extension(f) :: String

Returns the file extesion of `f`.
"""
file_extension(f) :: String = ormatch(match(r"(?<=\.)[^\.\\/]*$", f), "")


"""
    file_headers(f) :: Dict{AbstractString,AbstractString}

Returns the file headers of `f`.
"""
file_headers(f) :: Dict{AbstractString,AbstractString} = Dict{AbstractString,AbstractString}("Content-Type" => get(mimetypes, file_extension(f), "application/octet-stream"))

ormatch(r::RegexMatch, x) = r.match
ormatch(r::Void, x) = x

load_routes()

end
