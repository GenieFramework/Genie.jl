module Sessions

using Genie, SHA, HttpServer, Cookies, App

type Session
  id::AbstractString
  data::Dict{Symbol,Any}
end
Session(id::AbstractString) = Session(id, Dict{Symbol,Any}())

export Session

if IS_IN_APP
  const session_adapter_name = string(Genie.config.session_storage) * "SessionAdapter"
  eval(parse("using $session_adapter_name"))
  const SessionAdapter = eval(parse(session_adapter_name))
end

function id() :: String
  try
    App.SECRET_TOKEN * ":" * bytes2hex(sha1(string(Dates.now()))) * ":" * string(rand()) * ":" * string(hash(Genie)) |> sha256 |> bytes2hex
  catch ex
    # Genie.log(ex, :err)
    error("Can't compute session id - please make sure SECRET_TOKEN is defined in config/secrets.jl")
  end
end
function id(req::Request, res::Response) :: String
  ! isnull(Cookies.get(res, Genie.config.session_key_name)) && return Base.get(Cookies.get(res, Genie.config.session_key_name))
  ! isnull(Cookies.get(req, Genie.config.session_key_name)) && return Base.get(Cookies.get(req, Genie.config.session_key_name))

  id()
end

function start(session_id::AbstractString, req::Request, res::Response; options = Dict{String,String}()) :: Session
  options = merge(Dict("Path" => "/", "HttpOnly" => "", "Expires" => "0"), options)
  Cookies.set!(res, Genie.config.session_key_name, session_id, options)
  load(session_id)
end
function start(req::Request, res::Response) :: Session
  start(id(req, res), req, res)
end

function set!(s::Session, key::Symbol, value::Any) :: Session
  s.data[key] = value

  s
end

function get(s::Session, key::Symbol) :: Nullable
  return  if haskey(s.data, key)
            Nullable(s.data[key])
          else
            Nullable()
          end
end

function get!!(s::Session, key::Symbol)
  s.data[key]
end

function unset!(s::Session, key::Symbol) :: Session
  delete!(s.data, key)

  s
end

function is_set(s::Session, key::Symbol) :: Bool
  haskey(s.data, key)
end

function persist(s::Session) :: Session
  SessionAdapter.write(s)

  s
end

function load(session_id::AbstractString) :: Session
  session = SessionAdapter.read(session_id)
  if isnull(session)
    return Session(session_id)
  else
    return Base.get(session)
  end
end

end
