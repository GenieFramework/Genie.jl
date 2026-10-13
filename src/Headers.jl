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

  # merge!, in ascending priority (last wins), except Set-Cookie: HTTP.Headers accumulates
  # multiple Set-Cookie entries across sources instead of overwriting them -- see respond()
  # in Renderer.jl for the same pattern.
  headers = HTTP.Headers(["Server" => Genie.config.server_signature])
  merge!(headers, res.headers)
  merge!(headers, app_response.headers)

  # In HTTP.jl v2, create a new Response with updated headers
  return HTTP.Response(
    app_response.status;
    headers,
    body=app_response.body,
    request=app_response.request
  )
end

function set_access_control_allow_origin!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response
  request_origin = HTTP.header(req, "Origin", "")

  if ! isempty(request_origin)
    allowed_origin = occursin(request_origin |> lowercase, join(Genie.config.cors_allowed_origins, ',') |> lowercase) ||
                        in("*", Genie.config.cors_allowed_origins) ?
      request_origin :
      strip(Genie.config.cors_headers["Access-Control-Allow-Origin"])

    # Only this function's own CORS headers go here -- res.headers (session/cookie data)
    # is deliberately NOT merged in; that's set_headers!'s job, done exactly once, so that
    # a Set-Cookie from res doesn't get double-counted when this branch runs.
    headers = HTTP.Headers()
    merge!(headers, Genie.config.cors_headers)
    merge!(headers, ["Access-Control-Allow-Origin" => allowed_origin, "Vary" => "Origin"])
    merge!(headers, app_response.headers)

    # In HTTP.jl v2, create a new Response with updated headers
    return HTTP.Response(
      app_response.status;
      headers,
      body=app_response.body,
      request=app_response.request
    )
  end

  return app_response
end


function set_access_control_allow_headers!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response
  request_headers = HTTP.header(req, "Access-Control-Request-Headers", "")

  if ! isempty(request_headers)
    if isempty(Genie.config.cors_headers["Access-Control-Allow-Headers"])
      app_response.status = 403 # Forbidden
      if Genie.Configuration.isdev()
        @error "Access-Control-Allow-Headers is empty"
      end

      throw(Genie.Exceptions.ExceptionalResponse(app_response))
    end

    if Genie.config.cors_headers["Access-Control-Allow-Headers"] == "*"
      return app_response
    end

    for rqh in split(request_headers, ',')
      if ! occursin(strip(rqh) |> lowercase, Genie.config.cors_headers["Access-Control-Allow-Headers"] |> lowercase)
        if Genie.Configuration.isdev()
          @error "Access-Control-Allow-Headers mismatch: $rqh" Genie.config.cors_headers["Access-Control-Allow-Headers"]
        end

        app_response.status = 403 # Forbidden
        throw(Genie.Exceptions.ExceptionalResponse(app_response))
      end
    end
  end

  app_response
end


"""
    normalize_headers!(headers::HTTP.Headers) :: HTTP.Headers
    normalize_headers!(msg::Union{HTTP.Request,HTTP.Response}) :: Union{HTTP.Request,HTTP.Response}
    normalize_headers(msg)

Brings select known headers to standard casing in-place.
"""
function normalize_headers!(headers::HTTP.Headers) :: HTTP.Headers
  for i in eachindex(headers)
    k, v = headers[i]
    ks = string(k)
    if lowercase(ks) in NORMALIZED_HEADERS
      norm_k = normalize_header_key(ks)
      if ks != norm_k
        headers[i] = norm_k => string(v)
      end
    end
  end

  headers
end

function normalize_headers!(msg::Union{HTTP.Request,HTTP.Response}) :: Union{HTTP.Request,HTTP.Response}
  normalize_headers!(msg.headers)
  msg
end

const normalize_headers = normalize_headers!


"""
    normalize_header_key(key::String) :: String

Brings header keys to standard casing.
"""
function normalize_header_key(key::String) :: String
  join(map(x -> uppercasefirst(lowercase(x)), split(key, '-')), '-')
end


end
