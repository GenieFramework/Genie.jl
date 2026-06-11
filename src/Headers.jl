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

  headers = Pair{String,String}[]
  header_names = Set{String}()
  for h in Iterators.flatten(h for h in [app_response.headers, res.headers, ["Server" => Genie.config.server_signature]])
    if !in(h.first, header_names) || h.first == "Set-Cookie" # do not remove multiple "Set-Cookie" headers
      push!(headers, h)
      push!(header_names, h.first)
    end
  end

  # In HTTP.jl v2, create a new Response with updated headers
  return HTTP.Response(
    app_response.status;
    headers=HTTP.mkheaders(headers),
    body=app_response.body,
    request=app_response.request
  )
end

function set_access_control_allow_origin!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response
  request_origin = get(Dict(req.headers), "Origin", "")

  if ! isempty(request_origin)
    allowed_origin_dict = Dict("Access-Control-Allow-Origin" =>
      occursin(request_origin |> lowercase, join(Genie.config.cors_allowed_origins, ',') |> lowercase) ||
        in("*", Genie.config.cors_allowed_origins)
      ? request_origin
      : strip(Genie.config.cors_headers["Access-Control-Allow-Origin"])
    )
    allowed_origin_dict["Vary"] = "Origin"

    merged_headers = [d for d in merge(Genie.config.cors_headers, allowed_origin_dict, Dict(res.headers), Dict(app_response.headers))]

    # In HTTP.jl v2, create a new Response with updated headers
    return HTTP.Response(
      app_response.status;
      headers=HTTP.mkheaders(merged_headers),
      body=app_response.body,
      request=app_response.request
    )
  end

  return app_response
end


function set_access_control_allow_headers!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response
  request_headers = get(Dict(req.headers), "Access-Control-Request-Headers", "")

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
    normalize_headers(req::HTTP.Request)

Makes request headers case insensitive.
"""
function normalize_headers(req::HTTP.Request)
  normalized_headers = Pair{String,String}[]

  for (k,v) in req.headers
    if string(k) in NORMALIZED_HEADERS
      push!(normalized_headers, normalize_header_key(string(k)) => string(v))
    else
      push!(normalized_headers, string(k) => string(v))
    end
  end

  # In HTTP.jl v2, we need to create a new Request with normalized headers
  return HTTP.Request(
    req.method,
    req.target;
    headers=HTTP.mkheaders(normalized_headers),
    trailers=req.trailers,
    body=req.body,
    host=req.host,
    content_length=req.content_length,
    proto_major=req.proto_major,
    proto_minor=req.proto_minor,
    close=req.close,
    context=HTTP.get_request_context(req)
  )
end

function normalize_headers(res::HTTP.Response)
  normalized_headers = Pair{String,String}[]

  for (k,v) in res.headers
    if string(k) in NORMALIZED_HEADERS
      push!(normalized_headers, normalize_header_key(string(k)) => string(v))
    else
      push!(normalized_headers, string(k) => string(v))
    end
  end

  # In HTTP.jl v2, we need to create a new Response with normalized headers
  return HTTP.Response(
    res.status;
    headers=HTTP.mkheaders(normalized_headers),
    body=res.body,
    request=res.request
  )
end


"""
    normalize_header_key(key::String) :: String

Brings header keys to standard casing.
"""
function normalize_header_key(key::String) :: String
  join(map(x -> uppercasefirst(lowercase(x)), split(key, '-')), '-')
end


end
