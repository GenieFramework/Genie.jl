"""
Collection of utilities for working with Responses data
"""
module Responses

import Genie, Genie.Router
import HTTP

export getresponse, getheaders, setheaders, setheaders!, getstatus, setstatus, setstatus!, getbody, setbody, setbody!
export @streamhandler, stream


function getresponse() :: HTTP.Response
  Router.params(Genie.Router.PARAMS_RESPONSE_KEY)
end


function getheaders(res::HTTP.Response) :: Dict{String,String}
  Dict{String,String}(res.headers)
end
function getheaders() :: Dict{String,String}
  getheaders(getresponse())
end


function setheaders!(res::HTTP.Response, headers::Dict) :: HTTP.Response
  push!(res.headers, [headers...]...)

  res
end
function setheaders(headers::Dict) :: HTTP.Response
  setheaders!(getresponse(), headers)
end
function setheaders(header::Pair{String,String}) :: HTTP.Response
  setheaders(Dict(header))
end
function setheaders(headers::Vector{Pair{String,String}}) :: HTTP.Response
  setheaders(Dict(headers...))
end


function getstatus(res::HTTP.Response) :: Int
  res.status
end
function getstatus() :: Int
  getstatus(getresponse())
end


function setstatus!(res::HTTP.Response, status::Int) :: HTTP.Response
  res.status = status

  res
end
function setstatus(status::Int) :: HTTP.Response
  setstatus!(getresponse(), status)
end


function getbody(res::HTTP.Response) :: String
  String(res.body)
end
function getbody() :: String
  getbody(getresponse())
end


function setbody!(res::HTTP.Response, body::String) :: HTTP.Response
  res.body = collect(body)

  res
end
function setbody(body::String) :: HTTP.Response
  setbody!(getresponse(), body)
end


"""
@streamhandler(body)

Macro for defining a stream handler for a route.

# Example

```julia
route("/test") do
  @streamhandler begin
        while true
          stream("Hello")
          sleep(1)
        end
    end
end
````
"""
macro streamhandler(body)
  quote
    Genie.HTTPUtils.HTTP.setheader(Genie.Router.params(:STREAM), "Content-Type" => "text/event-stream")
    Genie.HTTPUtils.HTTP.setheader(Genie.Router.params(:STREAM), "Cache-Control" => "no-store")

    if Genie.HTTPUtils.HTTP.method(Genie.Router.params(:STREAM).message) == "OPTIONS"
      return nothing
    end

    response = try
      $body
    catch ex
      @error ex
    end

    if response !== nothing
      stream!(response.body |> String)
    end

    nothing
  end |> esc
end


function stream!(message::String; eol::String = "\n\n") :: Nothing
  Genie.HTTPUtils.HTTP.write(Genie.Router.params(:STREAM), message * eol)

  nothing
end
function stream(data::String = ""; event::String = "", id::String = "", retry::Int = 0) :: Nothing
  msg = ""
  if ! isempty(data)
    for line in split(data, "\n")
      msg = "data: $line\n" * msg
    end
  end
  if ! isempty(event)
    msg = "event: $event\n" * msg
  end
  if ! isempty(id)
    msg = "id: $id\n" * msg
  end
  if retry > 0
    msg = "retry: $retry\n" * msg
  end

  stream!(msg * "\n"; eol = "")

  nothing
end

end # module Responses
