function matchpath(target, path)
  length(target) > length(path) && return
  params = d()
  for i = 1:length(target)
    if startswith(target[i], ":")
      params[symbol(target[i][2:end])] = path[i]
    else
      target[i] == path[i] || return
    end
  end
  return params
end

function matchpath!(target, req)
  ps = Mux.matchpath(target, req[:path])
  ps == nothing && return false
  merge!(params!(req), ps)
  splice!(req[:path], 1:length(target))
  return true
end

# route(p, app...) = branch(req -> matchpath!(p, req), app...)
# route(p::AbstractString, app...) = route(splitpath(p), app...)
# route(app::Function, p) = route(p, app)

# page(p::Vector, app...) = branch(req -> length(p) == length(req[:path]) && matchpath!(p, req), app...)
# page(p::AbstractString, app...) = page(splitpath(p), app...)
# page(app...) = page([], app...)
# page(app::Function, p) = page(p, app)

# probabilty(x, app...) = branch(_->rand()<x, app...)

export @resources

http_verbs(verb, app...)    = branch(req -> lowercase(req[:method]) == string(verb) && length(req[:path]) == 0, app...) 
http_verbs(verb, sp::AbstractString, app...) = branch(req ->  lowercase(req[:method]) == string(verb) && 
                                                              Mux.matchpath!([sp[2:end]], req), 
                                                              app...) 

get(app) 		               = http_verbs(:get, app)
get(sp, app)               = http_verbs(:get, sp, app)
post(app) 	               = http_verbs(:post, app)
put(app) 		               = http_verbs(:put, app)
patch(app) 	               = http_verbs(:patch, app)
delete(app)                = http_verbs(:delete, app)

macro resources(routes_params...) 
  
  function extract_params(route_params)
    if ( length(routes_params) == 3 ) 
      return tuple(routes_params[1], eval(routes_params[2]), eval(routes_params[3]))
    elseif ( length(routes_params) == 2 ) 
      return tuple(routes_params[1], eval(routes_params[2]), [])
    elseif ( length(routes_params) == 1 ) 
      return tuple(routes_params[1], [], [])
    end
  end

  resource_name, only, except = extract_params(routes_params)

  http_verbs_actions = Dict(
    :get    => :index, 
    :post   => :create, 
    :put    => :update, 
    :patch  => :update, 
    :delete => :destroy
  )

  allowed_verbs = if ( ! isempty(only) ) 
   intersect( collect(keys(http_verbs_actions)), only ) 
  elseif ( ! isempty(except) ) 
    setdiff( collect(keys(http_verbs_actions)), except ) 
  else
    collect( keys(http_verbs_actions) )
  end

  allowed_verbs_actions = filter( (k,v)->in(k, allowed_verbs), http_verbs_actions)

  routes = ["Jinnie.$(verb)(req->$(method)($(ucfirst(resource_name))_Controller(),req))" for (verb, method) in allowed_verbs_actions]

  code =  """Mux.route("/$resource_name", $(join(routes, ",")), Mux.notfound())"""

  return parse(code)
end