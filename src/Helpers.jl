"""
Various utility functions for using across models, controllers and views.
"""
module Helpers

using Genie, Sessions, Router, URIParser, Logger, HttpServer, WebSockets

export session, request, response, flash, number_of_pages, paginated_uri, var_dump, wsclient, flash_has_message


"""
    session() :: Sessions.Session
    session(params::Dict{Symbol,Any}) :: Sessions.Session

Returns the `Session` object associated with the current HTTP request.
"""
function session() :: Sessions.Session
  session(Router._params_())
end
function session(params::Dict{Symbol,Any}) :: Sessions.Session
  if haskey(params, Genie.PARAMS_SESSION_KEY)
    return params[Genie.PARAMS_SESSION_KEY]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_SESSION_KEY) key"
    Logger.log(msg, :err)
    error(msg)
  end
end


"""
    request() :: HttpServer.Request
    request(params::Dict{Symbol,Any}) :: HttpServer.Request

Returns the `Request` object associated with the current HTTP request.
"""
function request() :: HttpServer.Request
  request(Router._params_())
end
function request(params::Dict{Symbol,Any}) :: HttpServer.Request
  if haskey(params, Genie.PARAMS_REQUEST_KEY)
    return params[Genie.PARAMS_REQUEST_KEY]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_REQUEST_KEY) key"
    Logger.log(msg, :err)
    error(msg)
  end
end


"""
    response() :: HttpServer.Response
    response(params::Dict{Symbol,Any}) :: HttpServer.Response

Returns the `Response` object associated with the current HTTP request.
"""
function response() :: HttpServer.Response
  response(Router._params_())
end
function response(params::Dict{Symbol,Any}) :: HttpServer.Response
  if haskey(params, Genie.PARAMS_RESPONSE_KEY)
    return params[Genie.PARAMS_RESPONSE_KEY]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_RESPONSE_KEY) key"
    Logger.log(msg, :err)
    error(msg)
  end
end


"""
    flash(params::Dict{Symbol,Any})

Returns the `flash` dict object associated with the current HTTP request.
"""
function flash()
  flash(Router._params_())
end
function flash(params::Dict{Symbol,Any})
  if haskey(params, Genie.PARAMS_FLASH_KEY)
    return params[Genie.PARAMS_FLASH_KEY]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_FLASH_KEY) key"
    Logger.log(msg, :err)
    error(msg)
  end
end


"""
    flash(value::Any) :: Void
    flash(value::Any, params::Dict{Symbol,Any}) :: Void

Stores `value` on the `flash`.
"""
function flash(value::Any) :: Void
  flash(value, Router._params_())
end
function flash(value::Any, params::Dict{Symbol,Any}) :: Void
  Sessions.set!(session(params), Genie.PARAMS_FLASH_KEY, value)
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
    Logger.log(msg, :err)
    error(msg)
  end
end

end
