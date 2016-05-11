module Router

using App
using HttpServer
using Debug
using URIParser
using Jinnie
using AppServer

export route, routes, params
export GET, POST, PUT, PATCH, DELETE

const GET     = "GET"
const POST    = "POST"
const PUT     = "PUT"
const PATCH   = "PATCH"
const DELETE  = "DELETE"

routes = Array{Any, 1}()
params = Dict{Symbol, Any}()

function route_request(req::Request, res::Response)
  empty!(params)

  if isempty(routes) 
    load_routes_from_file()
  elseif App.is_dev()
    empty!(routes)
    load_routes_from_file()
    Jinnie.load_models()
  end

  match_routes(req, res)
end

function route(params...; with::Dict{Symbol, Any} = Dict{Symbol, Any}())
  extra_params = Dict(:with => with)
  push!(routes, (params, extra_params))
end

function match_routes(req::Request, res::Response)
  for r in routes
    route_def, extra_params = r
    protocol, route, to = route_def
    protocol != req.method && continue
    
    Jinnie.config.debug_router ? Jinnie.log("Router: Checking against " * route) : nothing

    parsed_route, param_names = parse_route(route)

    uri = URI(req.resource)
    regex_route = Regex("^" * parsed_route * "\$")
    
    (! ismatch(regex_route, uri.path)) && continue
    Jinnie.config.debug_router ? Jinnie.log("Router: Matched route " * uri.path) : nothing

    extract_uri_params(uri, regex_route, param_names)
    extract_extra_params(extra_params)

    return invoke_controller(to, req, res, params)
  end

  Jinnie.config.debug_router ? Jinnie.log("Router: No route matched - defaulting 404") : nothing
  Response( 404, Dict{AbstractString, AbstractString}(), "not found" )
end

function parse_route(route::AbstractString)
  parts = Array{AbstractString, 1}()
  param_names = Array{AbstractString, 1}()

  for rp in split(route, "/", keep = false)
    if startswith(rp, ":")
      param_name = rp[2:end]
      rp = """(?P<$param_name>\\w+)"""
      push!(param_names, param_name)
    end
    push!(parts, rp)
  end

  "/" * join(parts, "/"), param_names
end

@debug function extract_uri_params(uri::URI, regex_route::Regex, param_names::Array{AbstractString, 1})
  # in path params
  matches = match(regex_route, uri.path)
  for param_name in param_names 
    params[Symbol(param_name)] = matches[param_name]
  end

  # GET params
  if ! isempty(uri.query)
    for query_part in split(uri.query, "&")
      qp = split(query_part, "=")
      params[Symbol(qp[1])] = qp[2]
    end
  end

  # POST params
  

  # pagination
  if ! haskey(params, Symbol("$(Jinnie.jinnie_app.config.pagination_jsonapi_page_param_name)_number"))
    params[Symbol("$(Jinnie.jinnie_app.config.pagination_jsonapi_page_param_name)_number")] = haskey(params, Symbol("$(Jinnie.jinnie_app.config.pagination_jsonapi_page_param_name)[number]")) ? parse(Int, params[Symbol("$(Jinnie.jinnie_app.config.pagination_jsonapi_page_param_name)[number]")]) : 1
  end
  if ! haskey(params, Symbol("$(Jinnie.jinnie_app.config.pagination_jsonapi_page_param_name)_size"))
    params[Symbol("$(Jinnie.jinnie_app.config.pagination_jsonapi_page_param_name)_size")] = haskey(params, Symbol("$(Jinnie.jinnie_app.config.pagination_jsonapi_page_param_name)[size]")) ? parse(Int, params[Symbol("$(Jinnie.jinnie_app.config.pagination_jsonapi_page_param_name)[size]")]) : Jinnie.jinnie_app.config.pagination_jsonapi_default_items_per_page
  end
end

function extract_extra_params(extra_params::Dict{Symbol, Dict{Symbol, Any}})
  if ! isempty(extra_params[:with])
    for (k, v) in extra_params[:with]
      params[k] = v
    end
  end
end

@debug function invoke_controller(to::AbstractString, req::Request, res::Response, params::Dict{Symbol, Any})
  to_parts = split(to, "#")
  Jinnie.load_controller(abspath(joinpath(Jinnie.APP_PATH, "app", "resources", to_parts[1])))

  controller = Jinnie.JinnieController()
  action_name = string(current_module()) * "." * to_parts[2]

  response = invoke( eval(parse(string(current_module()) * "." * action_name)), ( typeof(controller), typeof(params), typeof(req), typeof(res) ), controller, params, req, res )

  if ! isa(response, Response)
    if isa(response, Tuple)
      response = Response(response...)
    else
      response = Response(response)
    end
  end

  Jinnie.config.debug_responses ? AppServer.log_request_response(response) : nothing

  response
end

function load_routes_from_file()
  include(abspath("config/routes.jl")) 
end

end