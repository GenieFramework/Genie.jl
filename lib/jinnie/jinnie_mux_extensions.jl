# function matchpath!(target, req)
#   ps = matchpath(target, req[:path])
#   ps == nothing && return false
#   merge!(params!(req), ps)
#   splice!(req[:path], 1:length(target))
#   return true
# end

# route(p, app...) = branch(req -> matchpath!(p, req), app...)
# route(p::AbstractString, app...) = route(splitpath(p), app...)
# route(app::Function, p) = route(p, app)

# page(p::Vector, app...) = branch(req -> length(p) == length(req[:path]) && matchpath!(p, req), app...)
# page(p::AbstractString, app...) = page(splitpath(p), app...)
# page(app...) = page([], app...)
# page(app::Function, p) = page(p, app)

# probabilty(x, app...) = branch(_->rand()<x, app...)

export @resources

http_verbs(verb, app...) = branch(req -> lowercase(req[:method]) == string(verb), app...) 

get(app) 		= http_verbs(:get, app)
post(app) 	= http_verbs(:post, app)
put(app) 		= http_verbs(:put, app)
patch(app) 	= http_verbs(:patch, app)
delete(app) = http_verbs(:delete, app)

macro resources(routes_params...) 
  
  if ( length(routes_params) == 3 ) 
    routes_params = tuple(string(routes_params[1]), eval(routes_params[2]), eval(routes_params[3]))
  elseif ( length(routes_params) == 2 ) 
    routes_params = tuple(string(routes_params[1]), eval(routes_params[2]), [])
  elseif ( length(routes_params) == 1 ) 
    routes_params = tuple(string(routes_params[1]), [], [])
  end

  resource_name, only, except = routes_params

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

  code = """Mux.page("/$resource_name", $(join(routes, ",")), Mux.notfound())"""

  return parse(code)
end