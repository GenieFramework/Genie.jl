module Headers

import Revise, HTTP
import Genie

"""
    set_headers!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response

Configures the response headers.
"""
function set_headers!(req::HTTP.Request, res::HTTP.Response, app_response::HTTP.Response) :: HTTP.Response
  if req.method == Genie.Router.OPTIONS || req.method == Genie.Router.GET

    request_origin = get(Dict(req.headers), "Origin", "")

    allowed_origin_dict = Dict("Access-Control-Allow-Origin" =>
      in(request_origin, Genie.config.cors_allowed_origins)
      ? request_origin
      : strip(Genie.config.cors_headers["Access-Control-Allow-Origin"])
    )

    app_response.headers = [d for d in merge(Genie.config.cors_headers, allowed_origin_dict, Dict(res.headers), Dict(app_response.headers))]
  end

  app_response.headers = [d for d in merge(Dict(res.headers), Dict(app_response.headers))]

  app_response
end


"""
    sign_response!(res::HTTP.Response) :: HTTP.Response

Adds a signature header to the response using the value in `Genie.config.server_signature`.
If `Genie.config.server_signature` is empty, the header is not added.
"""
function sign_response!(res::HTTP.Response) :: HTTP.Response
  headers = Dict(res.headers)
  isempty(Genie.config.server_signature) || (headers["Server"] = Genie.config.server_signature)

  res.headers = [k for k in headers]
  res
end


function normalize_headers(req::HTTP.Request) :: HTTP.Request
  headers = Dict(req.headers)
  normalized_headers = Dict{String,String}()

  for (k,v) in headers
    normalized_headers[normalize_header_key(string(k))] = string(v)
  end

  req.headers = [k for k in normalized_headers]

  req
end


function normalize_header_key(key::String) :: String
  join(map(x -> uppercasefirst(lowercase(x)), split(key, '-')), '-')
end

end