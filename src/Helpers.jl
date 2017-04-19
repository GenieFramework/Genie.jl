module Helpers

using Genie, Sessions, Router, URIParser, Logger, HttpServer

export session, request, response, flash, number_of_pages, paginated_uri, var_dump

function session(params::Dict{Symbol,Any}) :: Sessions.Session
  if haskey(params, Genie.PARAMS_SESSION_KEY)
    return params[Genie.PARAMS_SESSION_KEY]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_SESSION_KEY) key"
    Logger.log(msg, :err)
    error(msg)
  end
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

function response(params::Dict{Symbol,Any}) :: HttpServer.Response
  if haskey(params, Genie.PARAMS_RESPONSE_KEY)
    return params[Genie.PARAMS_RESPONSE_KEY]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_RESPONSE_KEY) key"
    Logger.log(msg, :err)
    error(msg)
  end
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
function flash(value::Any, params::Dict{Symbol,Any})
  Sessions.set!(session(params), Genie.PARAMS_FLASH_KEY, value)
  params[Genie.PARAMS_FLASH_KEY] = value
end

end
