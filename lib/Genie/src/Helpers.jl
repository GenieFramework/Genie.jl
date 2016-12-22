module Helpers

using Genie, Sessions, Router, URIParser

export session, request, response, flash, number_of_pages, paginated_uri

function session(params::Dict{Symbol,Any})
  if haskey(params, Genie.PARAMS_SESSION_KEY)
    return params[Genie.PARAMS_SESSION_KEY]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_SESSION_KEY) key"
    Logger.log(msg, :err)
    error(msg)
  end
end

function request(params::Dict{Symbol,Any})
  if haskey(params, Genie.PARAMS_REQUEST_KEY)
    return params[Genie.PARAMS_REQUEST_KEY]
  else
    msg = "Invalid params Dict -- must have $(Genie.PARAMS_REQUEST_KEY) key"
    Logger.log(msg, :err)
    error(msg)
  end
end

function response(params::Dict{Symbol,Any})
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

function number_of_pages(params)
  convert(Int, ceil(params[:pagination_total]/params[:page_size]))
end

function paginated_uri(params, page)
  uri = params[Genie.PARAMS_REQUEST_KEY].resource
  uri_query = URI(uri).query
  uri_query_parts = AbstractString[]
  added_pagination = false
  for uqp in split(uri_query, "&", keep = false)
    if startswith(uqp, "page[number]=")
      push!(uri_query_parts, "page[number]=$page")
      added_pagination = true
    else
      push!(uri_query_parts, uqp)
    end
  end

  ! added_pagination && push!(uri_query_parts, "page[number]=$page")

  isempty(uri_query) ? uri * "?" * join(uri_query_parts, "&") : replace(uri, uri_query, join(uri_query_parts, "&"))
end

end