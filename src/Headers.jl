"""
Provides functionality for working with HTTP headers in Genie.
"""
module Headers

import HTTP
import Genie

const NORMALIZED_HEADERS = ["access-control-allow-origin", "origin",
                            "access-control-allow-headers", "access-control-request-headers", "access-control-expose-headers",
                            "access-control-max-age", "access-control-allow-credentials", "access-control-allow-methods",
                            "cookie", "set-cookie",
                            "content-type", "content-disposition",
                            "server"]

"""
    set_headers!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response

Configures the response headers.
"""
function set_headers!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response
  app_response = set_access_control_allow_origin!(req, res, app_response)
  app_response = set_access_control_allow_headers!(req, res, app_response)

  app_response.headers = [d for d in merge(Dict(res.headers), Dict(app_response.headers), Dict("Server" => Genie.config.server_signature))]

  app_response
end

function set_access_control_allow_origin!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response
  request_origin = get(Dict(req.headers), "Origin", "")

  if ! isempty(request_origin)
    allowed_origin_dict = Dict("Access-Control-Allow-Origin" =>
      contains(request_origin |> lowercase, join(Genie.config.cors_allowed_origins, ',') |> lowercase) ||
        in("*", Genie.config.cors_allowed_origins)
      ? request_origin
      : strip(Genie.config.cors_headers["Access-Control-Allow-Origin"])
    )
    allowed_origin_dict["Vary"] = "Origin"

    app_response.headers = [d for d in merge(Genie.config.cors_headers, allowed_origin_dict, Dict(res.headers), Dict(app_response.headers))]
  end

  app_response
end


function set_access_control_allow_headers!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response
  request_headers = get(Dict(req.headers), "Access-Control-Request-Headers", "")

  if ! isempty(request_headers)
    for rqh in split(request_headers, ',')
      if ! contains(strip(rqh) |> lowercase, Genie.config.cors_headers["Access-Control-Allow-Headers"] |> lowercase)
        app_response.status = 403 # Forbidden
        throw(Genie.Exceptions.ExceptionalResponse(app_response))
      end
    end
  end

  app_response
end





"""
    normalize_headers(req::HTTP.Request)

Makes request headers case insensitive.
"""
function normalize_headers(req::Union{HTTP.Request,HTTP.Response})
  headers = Dict(req.headers)
  normalized_headers = Dict{String,String}()

  for (k,v) in headers
    string(k) in NORMALIZED_HEADERS ?
      normalized_headers[normalize_header_key(string(k))] = string(v) :
      normalized_headers[string(k)] = string(v)
  end

  req.headers = [normalized_headers...]

  req
end


"""
    normalize_header_key(key::String) :: String

Brings header keys to standard casing.
"""
function normalize_header_key(key::String) :: String
  join(map(x -> uppercasefirst(lowercase(x)), split(key, '-')), '-')
end


end