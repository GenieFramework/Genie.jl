module Sessions

# export Session

using Genie
using SHA
using HttpServer
using Cookies

const session_adapter_name = string(Genie.config.session_storage) * "SessionAdapter"
eval(parse("using " * session_adapter_name))
const SessionAdapter = eval(parse(session_adapter_name))

type Session
  id::AbstractString
  data::Dict{Symbol,Any}
end
Session(id::AbstractString) = Session(id, Dict{Symbol,Any}())

function id()
  Genie.SECRET_TOKEN * ":" * sha1(string(Dates.now())) * ":" * string(rand()) * ":" * string(hash(Genie)) |> sha256
end

function id(req::Request, res::Response)
  ! isnull(Cookies.get(res, Genie.config.session_key_name)) && return Base.get(Cookies.get(res, Genie.config.session_key_name))
  ! isnull(Cookies.get(req, Genie.config.session_key_name)) && return Base.get(Cookies.get(req, Genie.config.session_key_name))

  id()
end

function start{T<:AbstractString}(session_id::AbstractString, req::Request, res::Response; options = Dict{T,T}())
  options = merge(Dict("Path" => "/", "HttpOnly" => "", "Expires" => "0"), options)
  Cookies.set!(res, Genie.config.session_key_name, session_id, options)
  load(session_id)
end
function start(req::Request, res::Response)
  start(id(req, res), req, res)
end

function set!(s::Session, key::Symbol, value::Any)
  s.data[key] = value
end

function get(s::Session, key::Symbol)
  return  if haskey(s.data, key)
            Nullable(s.data[key])
          else
            Nullable()
          end
end

function get!!(s::Session, key::Symbol)
  s.data[key]
end

function unset!(s::Session, key::Symbol)
  delete!(s.data, key)
end

function is_set(s::Session, key::Symbol)
  haskey(s.data, key)
end

function persist(s::Session)
  SessionAdapter.write(s)
end

function load(session_id::AbstractString)
  session = SessionAdapter.read(session_id)
  if isnull(session)
    return Session(session_id)
  else
    return Base.get(session)
  end
end

end