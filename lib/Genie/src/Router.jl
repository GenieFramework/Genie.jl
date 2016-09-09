module Router

using HttpServer
using URIParser
using Genie
using AppServer
using Memoize
using Sessions
using Millboard

import HttpServer.mimetypes

include(abspath(joinpath("lib", "Genie", "src", "router_converters.jl")))

export route, routes, params
export GET, POST, PUT, PATCH, DELETE
export to_link!!, to_link

const GET     = "GET"
const POST    = "POST"
const PUT     = "PUT"
const PATCH   = "PATCH"
const DELETE  = "DELETE"

const BEFORE_ACTION_HOOKS = :before_action

const _routes = Dict{Symbol,Any}()
const _params = Dict{Symbol,Any}()

function route_request(req::Request, res::Response, session::Sessions.Session)
  empty!(_params)

  if is_static_file(req.resource)
    Genie.config.server_handle_static_files && return serve_static_file(req.resource)
    return serve_error_file(404, "File not found: $(req.resource)")
  end

  if is_dev()
    load_routes()
    Genie.load_models()
    # Genie.reload_helpers()
  end

  match_routes(req, res, session)
end

function route(params...; with::Dict = Dict{Any,Any}(), named::Symbol = :__anonymous_route)
  extra_params = Dict(:with => with)
  named = named == :__anonymous_route ? route_name(params) : named
  if haskey(_routes, named)
    Genie.log(
      "Conflicting routes names - multiple routes are sharing the same name. Use the 'named' option to assign them different identifiers.\n" *
      string(_routes[named]) * "\n" *
      string((params, extra_params))
      , :warn)
  end
  _routes[named] = (params, extra_params)
end

function route_name(params)
  route_parts = AbstractString[lowercase(params[1])]
  for uri_part in split(params[2], "/", keep = false)
    startswith(uri_part, ":") && continue # we ignore named params
    push!(route_parts, lowercase(uri_part))
  end

  join(route_parts, "_") |> Symbol
end

function named_routes()
  _routes
end

function print_named_routes()
  Millboard.table(named_routes())
end

function get_route(route_name::Symbol)
  haskey(named_routes(), route_name) ? Nullable(named_routes()[route_name]) : Nullable()
end
function get_route!!(route_name::Symbol)
  r = get_route(route_name)
  ! isnull(r) ? Base.get(r) : error("Route $route_name does not exist")
end

function routes()
  collect(values(_routes))
end

function print_routes()
  Millboard.table(routes())
end

function to_link!!{T}(route_name::Symbol, route_params::Dict{Symbol,T} = Dict{Symbol,T}())
  route = get_route!!(route_name)
  result = AbstractString[]
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
function to_link{T}(route_name::Symbol, route_params::Dict{Symbol,T} = Dict{Symbol,T}())
  try
    to_link!!(route_name, route_params)
  catch ex
    Genie.log(ex, :err, showst = false)
    ""
  end
end
function to_link!!(route_name::Symbol; route_params...)
  d = Dict{Symbol,Any}()
  for (k,v) in route_params
    d[k] = v
  end

  to_link!!(route_name, d)
end
function to_link(route_name::Symbol; route_params...)
  d = Dict{Symbol,Any}()
  for (k,v) in route_params
    d[k] = v
  end

  try
    to_link!!(route_name, d)
  catch ex
    Genie.log(ex, :err, showst = false)
    ""
  end
end

function match_routes(req::Request, res::Response, session::Sessions.Session)
  for r in routes()
    route_def, extra_params = r
    protocol, route, to = route_def
    protocol != req.method && continue

    Genie.config.log_router && Genie.log("Router: Checking against " * route)

    parsed_route, param_names, param_types = parse_route(route)

    uri = URI(req.resource)
    regex_route = Regex("^" * parsed_route * "\$")

    (! ismatch(regex_route, uri.path)) && continue
    Genie.config.log_router && Genie.log("Router: Matched route " * uri.path)
    (! extract_uri_params(uri, regex_route, param_names, param_types)) && continue
    Genie.config.log_router && Genie.log("Router: Matched type of route " * uri.path)
    extract_post_params(req)
    extract_extra_params(extra_params)
    extract_pagination_params()

    return invoke_controller(to, req, res, _params, session)
  end

  Genie.config.log_router && Genie.log("Router: No route matched - defaulting 404", :err)
  serve_error_file(404, "Not found")
end

function parse_route(route::AbstractString)
  parts = Array{AbstractString,1}()
  param_names = Array{AbstractString,1}()
  param_types = Array{Any,1}()

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

function extract_uri_params(uri::URI, regex_route::Regex, param_names::Array{AbstractString,1}, param_types::Array{Any,1})
  # in path params
  matches = match(regex_route, uri.path)
  i = 1
  for param_name in param_names
    try
      _params[Symbol(param_name)] = convert(param_types[i], matches[param_name])
    catch ex
      Genie.log(ex)
      return false
    end

    i += 1
  end

  # GET params
  if ! isempty(uri.query)
    for query_part in split(uri.query, "&")
      qp = split(query_part, "=")
      (size(qp)[1] == 1) && (push!(qp, ""))
      _params[Symbol(qp[1])] = qp[2]
    end
  end

  true
end

function extract_extra_params(extra_params::Dict)
  if ! isempty(extra_params[:with])
    for (k, v) in extra_params[:with]
      _params[Symbol(k)] = v
    end
  end
end

function extract_post_params(req::Request)
  for (k, v) in Input.post(req)
    v = replace(v, "+", " ")
    nested_keys(k, v)
    _params[Symbol(k)] = v
  end
end

function nested_keys(k::AbstractString, v)
  if contains(k, ".")
    parts = split(k, ".", limit = 2)
    nested_val_key = Symbol(parts[1])
    if haskey(_params, nested_val_key) && isa(_params[nested_val_key], Dict)
      ! haskey(_params[nested_val_key], Symbol(parts[2])) && (_params[nested_val_key][Symbol(parts[2])] = v)
    elseif ! haskey(_params, nested_val_key)
      _params[nested_val_key] = Dict()
      _params[nested_val_key][Symbol(parts[2])] = v
    end
  end
end

function extract_pagination_params()
  if ! haskey(_params, :page_number)
    _params[:page_number] = haskey(_params, Symbol("page[number]")) ? parse(Int, _params[Symbol("page[number]")]) : 1
  end
  if ! haskey(_params, :page_size)
    _params[:page_size] = haskey(_params, Symbol("page[size]")) ? parse(Int, _params[Symbol("page[size]")]) : Genie.config.pagination_default_items_per_page
  end
end

function setup_params!( params::Dict{Symbol,Any}, to_parts::Vector{AbstractString}, action_controller_parts::Vector{AbstractString},
                        controller_path::AbstractString, req::Request, res::Response, session::Sessions.Session, action_name::AbstractString)
  params[:action_controller] = to_parts[2]
  params[:action] = action_controller_parts[end]
  params[:controller] = join(action_controller_parts[1:end-1], ".")

  params[Genie.PARAMS_REQUEST_KEY]   = req
  params[Genie.PARAMS_RESPONSE_KEY]  = res
  params[Genie.PARAMS_SESSION_KEY]   = session
  params[Genie.PARAMS_FLASH_KEY]     = begin
                                      s = Sessions.get(session, Genie.PARAMS_FLASH_KEY)
                                      if isnull(s)
                                        ""::AbstractString
                                      else
                                        ss = Base.get(s)
                                        Sessions.unset!(session, Genie.PARAMS_FLASH_KEY)
                                        ss
                                      end
                                    end

  Genie.config.log_requests && Genie.log("Invoking $action_name with params: \n" * string(Millboard.table(params)), :debug)

  params
end

const loaded_controllers = UInt64[]

function invoke_controller(to::AbstractString, req::Request, res::Response, params::Dict{Symbol,Any}, session::Sessions.Session)
  to_parts::Vector{AbstractString} = split(to, "#")

  controller_path = abspath(joinpath(Genie.APP_PATH, "app", "resources", to_parts[1]))
  controller_path_hash = hash(controller_path)
  if ! in(controller_path_hash, loaded_controllers) || Configuration.is_dev()
    Genie.load_controller(controller_path)
    Genie.export_controllers(to_parts[2])
    ! in(controller_path_hash, loaded_controllers) && push!(loaded_controllers, controller_path_hash)
  end

  controller = Genie.GenieController()
  action_name = string(current_module()) * "." * to_parts[2]

  action_controller_parts::Vector{AbstractString} = split(to_parts[2], ".")
  setup_params!(params, to_parts, action_controller_parts, controller_path, req, res, session, action_name)
  params[Genie.PARAMS_ACL_KEY] = Genie.load_acl(controller_path)

  try
    hook_result = run_hooks(BEFORE_ACTION_HOOKS, eval(Genie, parse(join(split(action_name, ".")[1:end-1], "."))), params)
    hook_stop(hook_result) && return to_response(hook_result[2])
  catch ex
    Genie.log("Failed to invoke hooks $(BEFORE_ACTION_HOOKS)", :err, showst = false)
    Genie.log(ex, :err, showst = false)
    show_stacktrace(catch_stacktrace())

    return serve_error_file(500, string(ex) * "<br/><br/>" * join(catch_stacktrace(), "<br/>"))
  end


  action_result = try
                    eval(Genie, parse(string(current_module()) * "." * action_name))(params)
                  catch ex
                    Genie.log("$ex at $(@__FILE__):$(@__LINE__)", :critical, showst = false)
                    Genie.log("While invoking $(string(current_module())).$(action_name) with $(params)", :critical, showst = false)
                    show_stacktrace(catch_stacktrace())

                    serve_error_file(500, string(ex) * "<br/><br/>" * join(catch_stacktrace(), "<br/>"))
                  end

  to_response(action_result)
end

function to_response(action_result)
  if ! isa(action_result, Response)
    try
      if isa(action_result, Tuple)
        Response(action_result...)
      else
        Response(action_result)
      end
    catch ex
      Genie.log("Can't convert $action_result to HttpServer Response", :err)
      Genie.log(ex, :err)
      Response("")
    end
  else
    action_result
  end
end

function hook_stop(hook_result)
  isa(hook_result, Tuple) && ! hook_result[1]
end

function run_hooks(hook_type::Symbol, m::Module, params::Dict{Symbol,Any})
  if in(hook_type, names(m, true))
    hooks::Vector{Symbol} = getfield(m, hook_type)
    for hook in hooks
      r = eval(Genie, parse(string(hook)))(params)
      hook_stop(r) && return r
    end
  end
end

function load_routes()
  empty!(_routes)
  include(abspath("config/routes.jl"))

  true
end

@memoize function is_static_file(resource::AbstractString)
  isfile(file_path(URI(resource).path))
end

function serve_static_file(resource::AbstractString)
  f = file_path(URI(resource).path)
  Response(200, file_headers(f), open(readbytes, f))
end

function serve_error_file(error_code::Int, error_message::AbstractString = "")
  if is_dev()
    error_page =  open(Genie.DOC_ROOT_PATH * "/error-$(error_code).html") do f
                    readall(f)
                  end
    error_page = replace(error_page, "<error_message/>", error_message)
    Response(error_code, Dict{AbstractString,AbstractString}(), error_page)
  else
    f = file_path(URI("/error-$(error_code).html").path)
    Response(error_code, file_headers(f), open(readbytes, f))
  end
end

function file_path(resource::AbstractString)
  abspath(joinpath(Genie.config.server_document_root, resource[2:end]))
end

pathify(x) = replace(string(x), " ", "-") |> lowercase |> URIParser.escape

file_extension(f) = ormatch(match(r"(?<=\.)[^\.\\/]*$", f), "")
file_headers(f) = Dict{AbstractString, AbstractString}("Content-Type" => get(mimetypes, file_extension(f), "application/octet-stream"))

ormatch(r::RegexMatch, x) = r.match
ormatch(r::Void, x) = x

load_routes();

end