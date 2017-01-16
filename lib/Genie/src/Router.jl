module Router

using HttpServer, URIParser, Genie, AppServer, Memoize, Sessions, Millboard, Configuration, App, Input, Logger, Util, Renderer

import HttpServer.mimetypes

include(abspath(joinpath("lib", "Genie", "src", "router_converters.jl")))

export route, routes
export GET, POST, PUT, PATCH, DELETE
export to_link!!, to_link, response_type

const GET     = "GET"
const POST    = "POST"
const PUT     = "PUT"
const PATCH   = "PATCH"
const DELETE  = "DELETE"

const BEFORE_ACTION_HOOKS = :before_action

const _routes = Dict{Symbol,Any}()
const sessionless = Symbol[:json]

type Params{T}
  collection::Dict{Symbol,T}
end
Params() = Params(Dict{Symbol,Any}())

function response_type{T}(params::Dict{Symbol,T}) :: Symbol
  haskey(params, :response_type) ? params[:response_type] : collect(keys(Renderer.CONTENT_TYPES))[1]
end
function response_type{T}(check::Symbol, params::Dict{Symbol,T}) :: Bool
  check == response_type(params)
end
function response_type(params::Params) :: Symbol
  response_type(params.collection)
end

function route_request(req::Request, res::Response, ip::IPv4 = ip"0.0.0.0") :: Response
  params = Params()
  params.collection[:request_ipv4] = ip

  extract_get_params(URI(req.resource), params)
  res = negotiate_content(req, res, params)

  if is_static_file(req.resource)
    Genie.config.server_handle_static_files && return serve_static_file(req.resource)
    return serve_error_file(404, "File not found: $(req.resource)", params.collection)
  end

  if is_dev()
    load_routes()
    App.load_models()
  end

  session = Sessions.start(req, res)

  controller_response::Response = match_routes(req, res, session, params)

  ! in(response_type(params), sessionless) && Sessions.persist(session)

  controller_response
end

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

function route(params...; with::Dict = Dict{Symbol,Any}(), named::Symbol = :__anonymous_route) :: Tuple{Tuple{String,String,String},Dict{Symbol,Dict{Any,Any}}}
  extra_params = Dict(:with => with)
  named = named == :__anonymous_route ? route_name(params) : named
  if haskey(_routes, named)
    Logger.log(
      "Conflicting routes names - multiple routes are sharing the same name. Use the 'named' option to assign them different identifiers.\n" *
      string(_routes[named]) * "\n" *
      string((params, extra_params))
      , :warn)
  end
  _routes[named] = (params, extra_params)
end

function route_name(params) :: Symbol
  route_parts = AbstractString[lowercase(params[1])]
  for uri_part in split(params[2], "/", keep = false)
    startswith(uri_part, ":") && continue # we ignore named params
    push!(route_parts, lowercase(uri_part))
  end

  join(route_parts, "_") |> Symbol
end

function named_routes() :: Dict{Symbol,Any}
  _routes
end

function print_named_routes() :: Void
  Millboard.table(named_routes())

  nothing
end

function get_route(route_name::Symbol) :: Nullable{Tuple{Tuple{String,String,String},Dict{Symbol,Dict{Any,Any}}}}
  haskey(named_routes(), route_name) ? Nullable(named_routes()[route_name]) : Nullable()
end

function get_route!!(route_name::Symbol) :: Tuple{Tuple{String,String,String},Dict{Symbol,Dict{Any,Any}}}
  get_route(route_name) |> Base.get
end

function routes() :: Array{Tuple{Tuple{String,String,String},Dict{Symbol,Dict{Any,Any}}}}
  collect(values(_routes))
end

function print_routes() :: Void
  Millboard.table(routes())

  nothing
end

function to_link!!{T}(route_name::Symbol, route_params::Dict{Symbol,T} = Dict{Symbol,T}(); with_error = true) :: String
  route = (with_error ? get_route!! : get_route)(route_name) |> Util.expand_nullable

  result = String[]
  for part in split(route[1][2], "/")
    if startswith(part, ":")
      var_name = split(part, "::")[1][2:end] |> Symbol
      ( isempty(route_params) || ! haskey(route_params, var_name) ) && error("Route $route_name expects param $var_name")
      push!(result, pathify(route_params[var_name]))
      continue
    end
    push!(result, part)
  end

  join(result, "/")
end
function to_link{T}(route_name::Symbol, route_params::Dict{Symbol,T} = Dict{Symbol,T}()) :: String
  try
    to_link!!(route_name, route_params, with_error = false)
  catch ex
    Logger.log(ex, :err, showst = false)
    ""
  end
end
function to_link!!(route_name::Symbol; route_params...) :: String
  d = Dict{Symbol,Any}()
  for (k,v) in route_params
    d[k] = v
  end

  to_link!!(route_name, d)
end
function to_link(route_name::Symbol; route_params...) :: String
  d = Dict{Symbol,Any}()
  for (k,v) in route_params
    d[k] = v
  end

  try
    to_link!!(route_name, d, with_error = false)
  catch ex
    Logger.log(ex, :err, showst = false)
    ""
  end
end

function match_routes(req::Request, res::Response, session::Sessions.Session, params::Params) :: Response
  for r in routes()
    route_def, extra_params = r
    protocol, route, to = route_def
    protocol != req.method && continue

    Genie.config.log_router && Logger.log("Router: Checking against " * route)

    parsed_route, param_names, param_types = parse_route(route)

    uri = URI(req.resource)
    regex_route = Regex("^" * parsed_route * "\$")

    (! ismatch(regex_route, uri.path)) && continue
    Genie.config.log_router && Logger.log("Router: Matched route " * uri.path)
    (! extract_uri_params(uri, regex_route, param_names, param_types, params)) && continue
    Genie.config.log_router && Logger.log("Router: Matched type of route " * uri.path)
    extract_post_params(req, params)
    extract_extra_params(extra_params, params)
    extract_pagination_params(params)

    res = negotiate_content(req, res, params)

    return  try
              invoke_controller(to, req, res, params.collection, session)
            catch ex
              if is_dev()
                rethrow(ex)
              else
                Logger.log("Failed invoking controller", :err, showst = false)
                Logger.@location()

                serve_error_file_500(ex, params.collection)
              end
            end
  end

  Genie.config.log_router && Logger.log("Router: No route matched - defaulting 404", :err)
  serve_error_file(404, "Not found", params.collection)
end

function parse_route(route::AbstractString) :: Tuple{AbstractString,Vector{AbstractString},Vector{Any}}
  parts = AbstractString[]
  param_names = AbstractString[]
  param_types = Any[]

  for rp in split(route, "/", keep = false)
    if startswith(rp, ":")
      param_type =  if contains(rp, "::")
                      x = split(rp, "::")
                      rp = x[1]
                      eval(parse(x[2]))
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

function extract_uri_params(uri::URI, regex_route::Regex, param_names::Vector{AbstractString}, param_types::Vector{Any}, params::Params) :: Bool
  matches = match(regex_route, uri.path)
  i = 1
  for param_name in param_names
    try
      params.collection[Symbol(param_name)] = convert(param_types[i], matches[param_name])
    catch ex
      Logger.log(ex)
      return false
    end

    i += 1
  end

  true # this must be bool cause it's used in bool context for chaining
end

function extract_get_params(uri::URI, params::Params) :: Bool
  # GET params
  if ! isempty(uri.query)
    for query_part in split(uri.query, "&")
      qp = split(query_part, "=")
      (size(qp)[1] == 1) && (push!(qp, ""))
      params.collection[Symbol(qp[1])] = qp[2]
    end
  end

  true # this must be bool cause it's used in bool context for chaining
end

function extract_extra_params(extra_params::Dict, params::Params) :: Void
  if ! isempty(extra_params[:with])
    for (k, v) in extra_params[:with]
      params.collection[Symbol(k)] = v
    end
  end

  nothing
end

function extract_post_params(req::Request, params::Params) :: Void
  for (k, v) in Input.post(req)
    v = replace(v, "+", " ")
    nested_keys(k, v, params)
    params.collection[Symbol(k)] = v
  end

  nothing
end

function nested_keys(k::AbstractString, v, params::Params) :: Void
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

function extract_pagination_params(params::Params) :: Void
  if ! haskey(params.collection, :page_number)
    params.collection[:page_number] = haskey(params.collection, Symbol("page[number]")) ? parse(Int, params.collection[Symbol("page[number]")]) : 1
  end
  if ! haskey(params.collection, :page_size)
    params.collection[:page_size] = haskey(params.collection, Symbol("page[size]")) ? parse(Int, params.collection[Symbol("page[size]")]) : Genie.config.pagination_default_items_per_page
  end

  nothing
end

function setup_params!( params::Dict{Symbol,Any}, to_parts::Vector{AbstractString}, action_controller_parts::Vector{AbstractString},
                        controller_path::AbstractString, req::Request, res::Response, session::Sessions.Session, action_name::AbstractString) :: Dict{Symbol,Any}
  params[:action_controller] = to_parts[2]
  params[:action] = action_controller_parts[end]
  params[:controller] = join(action_controller_parts[1:end-1], ".")

  params[Genie.PARAMS_REQUEST_KEY]   = req
  params[Genie.PARAMS_RESPONSE_KEY]  = res
  params[Genie.PARAMS_SESSION_KEY]   = session
  params[Genie.PARAMS_FLASH_KEY]     = begin
                                      s = Sessions.get(session, Genie.PARAMS_FLASH_KEY)
                                      if isnull(s)
                                        ""::String
                                      else
                                        ss = Base.get(s)
                                        Sessions.unset!(session, Genie.PARAMS_FLASH_KEY)
                                        ss
                                      end
                                    end

  Genie.config.log_requests && Logger.log("Invoking $action_name with params: \n" * string(Millboard.table(params)), :debug)

  params
end

const loaded_controllers = UInt64[]

function invoke_controller(to::AbstractString, req::Request, res::Response, params::Dict{Symbol,Any}, session::Sessions.Session) :: Response
  to_parts::Vector{AbstractString} = split(to, "#")

  controller_path = abspath(joinpath(Genie.RESOURCE_PATH, to_parts[1]))
  controller_path_hash = hash(controller_path)
  if ! in(controller_path_hash, loaded_controllers) || Configuration.is_dev()
    App.load_controller(controller_path)
    App.export_controllers(to_parts[2])
    ! in(controller_path_hash, loaded_controllers) && push!(loaded_controllers, controller_path_hash)
  end

  controller = Genie.GenieController()
  action_name = to_parts[2]

  action_controller_parts::Vector{AbstractString} = split(to_parts[2], ".")
  setup_params!(params, to_parts, action_controller_parts, controller_path, req, res, session, action_name)

  try
    params[Genie.PARAMS_ACL_KEY] = App.load_acl(controller_path)
  catch ex
    if Configuration.is_dev()
      rethrow(ex)
    else
      Logger.log("Failed loading ACL", :err, showst = false)
      Logger.@location()

      return serve_error_file_500(ex, params)
    end
  end

  try
    hook_result = run_hooks(BEFORE_ACTION_HOOKS, eval(App, parse(join(split(action_name, ".")[1:end-1], "."))), params)
    hook_stop(hook_result) && return to_response(hook_result[2])
  catch ex
    if Configuration.is_dev()
      rethrow(ex)
    else
      Logger.log("Failed to invoke hooks $(BEFORE_ACTION_HOOKS)", :err, showst = false)
      Logger.@location()

      return serve_error_file_500(ex, params)
    end
  end

  return  try
            eval(parse("App." * action_name))(params) |> to_response
          catch ex
            if Configuration.is_dev()
              rethrow(ex)
            else
              Logger.log("$ex at $(@__FILE__):$(@__LINE__)", :critical, showst = false)
              Logger.log("While invoking $(action_name) with $(params)", :critical, showst = false)
              Logger.@location()

              serve_error_file_500(ex, params)
            end
          end
end

function to_response(action_result) :: Response
  isa(action_result, Response) && return action_result

  return  try
            if isa(action_result, Tuple)
              Response(action_result...)
            else
              Response(action_result)
            end
          catch ex
            Logger.log("Can't convert $action_result to HttpServer Response", :err)
            Logger.@location()

            serve_error_file_500(ex)
          end
end

function serve_error_file_500(ex::Exception, params::Dict{Symbol,Any} = Dict{Symbol,Any}()) :: Response
  serve_error_file( 500,
                    string(ex) *
                    "<br/><br/>" *
                    join(catch_stacktrace(), "<br/>") *
                    "<hr/>" *
                    string(params)
                  )
end

function hook_stop(hook_result) :: Bool
  isa(hook_result, Tuple) && ! hook_result[1]
end

function run_hooks(hook_type::Symbol, m::Module, params::Dict{Symbol,Any}) :: Any
  if in(hook_type, names(m, true))
    hooks::Vector{Symbol} = getfield(m, hook_type)
    for hook in hooks
      r = eval(Genie, parse(string(hook)))(params)
      hook_stop(r) && return r
    end
  end
end
# FIX: this is type unstable

function load_routes() :: Void
  empty!(_routes)
  include(abspath(joinpath("config", "routes.jl")))

  nothing
end

function is_static_file(resource::AbstractString) :: Bool
  isfile(file_path(URI(resource).path))
end

function serve_static_file(resource::AbstractString) :: Response
  f = file_path(URI(resource).path)
  Response(200, file_headers(f), open(read, f))
end

function serve_error_file(error_code::Int, error_message::AbstractString = "", params::Dict{Symbol,Any} = Dict{Symbol,Any}()) :: Response
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

function file_path(resource::AbstractString) :: String
  abspath(joinpath(Genie.config.server_document_root, resource[2:end]))
end

pathify(x) :: String = replace(string(x), " ", "-") |> lowercase |> URIParser.escape

file_extension(f) :: String = ormatch(match(r"(?<=\.)[^\.\\/]*$", f), "")
file_headers(f) :: Dict{AbstractString,AbstractString} = Dict{AbstractString,AbstractString}("Content-Type" => get(mimetypes, file_extension(f), "application/octet-stream"))

ormatch(r::RegexMatch, x) = r.match
ormatch(r::Void, x) = x

load_routes()

end
