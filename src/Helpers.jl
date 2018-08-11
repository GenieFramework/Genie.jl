"""
Various utility functions for using across models, controllers and views.
"""
module Helpers

using Genie, Genie.Router, URIParser, Genie.Logger, HTTP, WebSockets, Genie.Flax

export request, response, flash, wsclient, flash_has_message



"""
    request() :: HttpServer.Request
    request(params::Dict{Symbol,Any}) :: HttpServer.Request

Returns the `Request` object associated with the current HTTP request.
"""
function request() :: HTTP.Request
  request(Genie.Router._params_())
end
function request(params::Dict{Symbol,Any}) :: HTTP.Request
  if haskey(params, Genie.PARAMS_REQUEST_KEY)
    return params[Genie.PARAMS_REQUEST_KEY]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_REQUEST_KEY) key"
    Genie.Logger.log(msg, :err)
    error(msg)
  end
end


"""
    response() :: HttpServer.Response
    response(params::Dict{Symbol,Any}) :: HttpServer.Response

Returns the `Response` object associated with the current HTTP request.
"""
function response() :: HTTP.Response
  response(Genie.Router._params_())
end
function response(params::Dict{Symbol,Any}) :: HTTP.Response
  if haskey(params, Genie.PARAMS_RESPONSE_KEY)
    return params[Genie.PARAMS_RESPONSE_KEY]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_RESPONSE_KEY) key"
    Genie.Logger.log(msg, :err)
    error(msg)
  end
end


"""
    flash(params::Dict{Symbol,Any})

Returns the `flash` dict object associated with the current HTTP request.
"""
function flash()
  flash(Genie.Router._params_())
end
function flash(params::Dict{Symbol,Any})
  if haskey(params, Genie.PARAMS_FLASH_KEY)
    return params[Genie.PARAMS_FLASH_KEY]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_FLASH_KEY) key"
    Genie.Logger.log(msg, :err)
    error(msg)
  end
end


"""
    flash(value::Any) :: Nothing
    flash(value::Any, params::Dict{Symbol,Any}) :: Nothing

Stores `value` on the `flash`.
"""
function flash(value::Any) :: Nothing
  flash(value, Genie.Router._params_())
end
function flash(value::Any, params::Dict{Symbol,Any}) :: Nothing
  Genie.Sessions.set!(session(params), Genie.PARAMS_FLASH_KEY, value)
  params[Genie.PARAMS_FLASH_KEY] = value

  nothing
end


"""

"""
function flash_has_message() :: Bool
  ! isempty(flash())
end


"""
    wsclient(params::Dict{Symbol,Any}) :: WebSockets.WebSocket

Returns the `WebSocket` object associated with the current WS request.
"""
function wsclient(params::Dict{Symbol,Any}) :: WebSockets.WebSocket
  if haskey(params, Genie.PARAMS_WS_CLIENT)
    return params[Genie.PARAMS_WS_CLIENT]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_WS_CLIENT) key"
    Genie.Logger.log(msg, :err)
    error(msg)
  end
end


"""
    include_helpers() :: Void

Loads helpers and makes them available in the view layer.
"""
function include_helpers() :: Void
  for h in readdir(Genie.HELPERS_PATH)
    if isfile(joinpath(Genie.HELPERS_PATH, h)) && endswith(h, "Helper.jl")
      eval(Genie.Flax, """include("$(joinpath(Genie.HELPERS_PATH, h))")""" |> parse)
      eval(Genie.Flax, """@reexport using .$(replace(h, r"\.jl$", ""))""" |> parse)
    end
  end

  nothing
end
include_helpers()

end
