module Session

using Genie
using SHA
using HttpServer

function id()
  Genie.SECRET_TOKEN * ":" * sha1(string(Dates.now())) * ":" * string(rand()) * ":" * string(hash(Genie)) |> sha256
end

function id(req::Request)
  if haskey(req.headers, "Cookie")
    cookies = cookies_dict(req)
    haskey(cookies, Genie.config.session_key_name) && return cookies[Genie.config.session_key_name]
  end

  id()
end

function start(req::Request, res::Response)
  setcookie!(res, Genie.config.session_key_name, id(req), Dict("Path" => "/", "HttpOnly" => "", "Expires" => "0"))
end

function cookies_dict(req::Request)
  d = Dict{AbstractString,AbstractString}()
  for cookie in split(req.headers["Cookie"], ";")
    cookie_parts = split(cookie, "=")
    d[strip(cookie_parts[1])] = cookie_parts[2]
  end

  d
end

end