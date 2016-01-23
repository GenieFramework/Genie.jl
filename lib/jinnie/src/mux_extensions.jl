using Mux

export @resources

ControllerActionParams = Union{Symbol, AbstractString}

function req!(req, controller, action) 
  req[:controller] = string(controller)
  req[:action] = string(action)
  true 
end

function rendering!(req, controller, action)
  renderer.view = abspath(joinpath("app/views", string(controller), string(action)))
  true
end

http_verbs(verb, p::Vector, controller::ControllerActionParams="", action::ControllerActionParams="", app...) = 
                                                            branch(
                                                              req -> 
                                                                lowercase(req[:method]) == string(verb) && 
                                                                length(p) == length(req[:path]) && 
                                                                Mux.matchpath!(p, req) && 
                                                                req!(req, controller, action) && 
                                                                rendering!(req, controller, action), 
                                                                app...
                                                            )
http_verbs(verb, p::AbstractString, app...) = http_verbs(verb, Mux.splitpath(p), "", "", app...)
http_verbs(verb, p::AbstractString, controller::ControllerActionParams, action::ControllerActionParams) = 
                                                            http_verbs(verb, Mux.splitpath(p), controller, action, 
                                                              eval(parse("req -> $(action)($(ucfirst(string(controller)))_Controller(), req)")))

get(p, app)                                                                       = http_verbs(:get, p, app)
get(p, controller::ControllerActionParams, action::ControllerActionParams)        = http_verbs(:get, p, controller, action)
post(p, app) 	                                                                    = http_verbs(:post, p, app)
post(p, controller::ControllerActionParams, action::ControllerActionParams)       = http_verbs(:post, p, controller, action)
put(p, app) 		                                                                  = http_verbs(:put, p, app)
put(p, controller::ControllerActionParams, action::ControllerActionParams)        = http_verbs(:put, p, controller, action)
patch(p, app) 	                                                                  = http_verbs(:patch, p, app)
patch(p, controller::ControllerActionParams, action::ControllerActionParams)      = http_verbs(:patch, p, controller, action)
delete(p, app)                                                                    = http_verbs(:delete, p, app)
delete(p, controller::ControllerActionParams, action::ControllerActionParams)     = http_verbs(:delete, p, controller, action)

root(app)                                                                         = get("/", app)
root(controller::ControllerActionParams, action::ControllerActionParams)          = get("/", controller, action)

macro resources(routes_params...) 
  function extract_params(route_params)
    if ( length(routes_params) == 3 ) 
      return (routes_params[1], eval(routes_params[2]), eval(routes_params[3]))
    elseif ( length(routes_params) == 2 ) 
      return (routes_params[1], eval(routes_params[2]), [])
    elseif ( length(routes_params) == 1 ) 
      return (routes_params[1], [], [])
    end
  end

  resource_name, only, except = #length(routes_params) == 2 && isa(routes_params[2], Dict) ? 
                                #(route_params[1], eval(eval(route_params[2])[:only]), eval(eval(route_params[2])[:except])) : 
                                extract_params(routes_params)

  rest_actions = Dict(
    :index    => Dict(:verb => :get,    :path => ""), 
    :show     => Dict(:verb => :get,    :path => "/:id"), 
    :new      => Dict(:verb => :get,    :path => "/new"), 
    :edit     => Dict(:verb => :get,    :path => "/:id/edit"), 
    :create   => Dict(:verb => :post,   :path => ""), 
    :update   => Dict(:verb => :put,    :path => "/:id"), 
    :update   => Dict(:verb => :patch,  :path => "/:id"), 
    :destroy  => Dict(:verb => :delete, :path => "/:id")
  )

  allowed_actions = if ( ! isempty(only) ) 
   intersect( collect(keys(rest_actions)), only ) 
  elseif ( ! isempty(except) ) 
    setdiff( collect(keys(rest_actions)), except ) 
  else
    collect( keys(rest_actions) )
  end

  allowed_rest_actions = filter( (k,v) -> in(k, allowed_actions), rest_actions)

  routes = ["""Jinnie.$(props[:verb])("/$(resource_name * props[:path])","$resource_name","$action")""" for (action, props) in allowed_rest_actions]

  code = length(routes) == 1 ? routes[1] * "," : join(routes, ",")

  return parse(code)
end