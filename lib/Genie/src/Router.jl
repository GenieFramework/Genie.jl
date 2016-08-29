module Router

using App
using HttpServer
using URIParser
using Genie
using AppServer
using URIParser
using Memoize
using Sessions
using Millboard

import HttpServer.mimetypes

include(abspath(joinpath("lib", "Genie", "src", "router_converters.jl")))

export route, routes, params
export GET, POST, PUT, PATCH, DELETE
export to_link!!

const GET     = "GET"
const POST    = "POST"
const PUT     = "PUT"
const PATCH   = "PATCH"
const DELETE  = "DELETE"

const _routes = Dict{Symbol,Any}()
const _params = Dict{Symbol,Any}()

function route_request(req::Request, res::Response, session::Sessions.Session)
  empty!(_params)

  if is_static_file(req.resource)
    Genie.config.server_handle_static_files && return serve_static_file(req.resource)
    return Response(404)
  end

  if App.is_dev()
    load_routes()
    Genie.load_models()
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
function to_link!!(route_name::Symbol; route_params...)
  d = Dict{Symbol,Any}()
  for (k,v) in route_params
    d[k] = v
  end

  to_link!!(route_name, d)
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
    Genie.config.app_is_api && extract_json_api_pagination_params()

    return invoke_controller(to, req, res, _params, session)
  end

  Genie.config.log_router && Genie.log("Router: No route matched - defaulting 404")
  Response( 404, Dict{AbstractString, AbstractString}(), "not found" )
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

function extract_json_api_pagination_params()
  # JSON API pagination
  if ! haskey(_params, Symbol("$(Genie.genie_app.config.pagination_jsonapi_page_param_name)_number"))
    _params[Symbol("$(Genie.genie_app.config.pagination_jsonapi_page_param_name)_number")] = haskey(_params, Symbol("$(Genie.genie_app.config.pagination_jsonapi_page_param_name)[number]")) ? parse(Int, params[Symbol("$(Genie.genie_app.config.pagination_jsonapi_page_param_name)[number]")]) : 1
  end
  if ! haskey(_params, Symbol("$(Genie.genie_app.config.pagination_jsonapi_page_param_name)_size"))
    _params[Symbol("$(Genie.genie_app.config.pagination_jsonapi_page_param_name)_size")] = haskey(_params, Symbol("$(Genie.genie_app.config.pagination_jsonapi_page_param_name)[size]")) ? parse(Int, params[Symbol("$(Genie.genie_app.config.pagination_jsonapi_page_param_name)[size]")]) : Genie.genie_app.config.pagination_jsonapi_default_items_per_page
  end
end

const loaded_controllers = UInt64[]

function invoke_controller(to::AbstractString, req::Request, res::Response, params::Dict{Symbol,Any}, session::Sessions.Session)
  to_parts = split(to, "#")

  controller_path = abspath(joinpath(Genie.APP_PATH, "app", "resources", to_parts[1]))
  controller_path_hash = hash(controller_path)
  if ! in(controller_path_hash, loaded_controllers) || Configuration.is_dev()
    Genie.load_controller(controller_path)
    Genie.export_controllers(to_parts[2])
    ! in(controller_path_hash, loaded_controllers) && push!(loaded_controllers, controller_path_hash)
  end

  controller = Genie.GenieController()
  action_name = string(current_module()) * "." * to_parts[2]

  action_controller_parts = split(to_parts[2], ".")
  params[:action_controller] = to_parts[2]
  params[:action] = action_controller_parts[end]
  params[:controller] = join(action_controller_parts[1:end-1], ".")

  params[Genie.PARAMS_ACL_KEY]       = Genie.load_acl(controller_path)
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

  try
    response = invoke(eval(Genie, parse(string(current_module()) * "." * action_name)), (typeof(params),), params)
  catch ex
    Genie.log("$ex at $(@__FILE__):$(@__LINE__)", :err, showst = false)
    Genie.log("While invoking $(string(current_module())).$(action_name) with $(params)", :err, showst = false)

    rethrow(ex) # do something better with the error
  end

  if ! isa(response, Response)
    response =  try
                  if isa(response, Tuple)
                    Response(response...)
                  else
                    Response(response)
                  end
                catch ex
                  Genie.log(ex, :err)
                  Response("")
                end
  end

  response
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