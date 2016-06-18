using HttpServer
using URIParser
using Requests
using Debug

const GET = "GET"
routes = []
params = Dict{Symbol, AbstractString}()

function start_server(port::Int = 8000)
  http = HttpHandler() do req::Request, res::Response
    router(req, res)
  end

  server = Server( http )
  run( server, port )
end

function run_server(port::Int = 8000)
  @spawn start_server(port)
end

function router(req::Request, res::Response)
  routes = []
  route(GET, "/packages", "packages#index", req, res)
  route(GET, "/packages/:package_id", "packages#show", req, res)
  # route(GET, "/packages/(?P<package_id>\\w+)", "packages#show", req, res)
  match_routes()
end

function route(params...)
  push!(routes, params)
end

@debug function match_routes()
  for r in routes
    global params
    protocol, route, to, req, res = r
    protocol != req.method && continue
    
    println(route)

    parts = []
    param_names = []
    for rp in split(route, "/", keep = false)
      if startswith(rp, ":")
        param_name = rp[2:end]
        rp = """(?P<$param_name>\\w+)"""
        push!(param_names, param_name)
      end
      push!(parts, rp)
    end

    parsed_route = "/" * join(parts, "/")

    uri = URI(req.resource)
    regex_route = Regex("^" * parsed_route * "\$")
    # @bp
    (! ismatch(regex_route, uri.path)) && continue

    matches = match(regex_route, uri.path)
    for param_name in param_names 
      @bp
      params[Symbol(param_name)] = matches[param_name]
    end

    println("matched " * uri.path)
    # @bp
    
    to_parts = split(to, "#")
    controller = ucfirst(to_parts[1]) * "Controller"
    action = to_parts[2]

    println("calling $action ($controller)()")

    return Response( 200, Dict{AbstractString, AbstractString}(), uri.path )
  end

  Response( 404, Dict{AbstractString, AbstractString}(), "not found" )
end