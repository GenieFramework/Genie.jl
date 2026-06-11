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


@inline function getheaders(res::HTTP.Response) :: HTTP.Headers
  res.headers
end
function getheaders() :: HTTP.Headers
  getheaders(getresponse())
end


function setheaders!(res::HTTP.Response, headers) :: HTTP.Response
  union!(append!(res.headers.entries, HTTP.mkheaders(headers)))

  res
end
function setheaders(headers) :: HTTP.Response
  setheaders!(getresponse(), headers)
end
function setheaders(header::Pair{String,String}) :: HTTP.Response
  setheaders([header])
end


function getstatus(res::HTTP.Response) :: Int
  res.status
end
function getstatus() :: Int
  getstatus(getresponse())
end


# Helper function to update response and store it in params
# In HTTP.jl v2, Response fields are immutable, so we create a new Response
function _update_response!(new_res::HTTP.Response) :: HTTP.Response
  Router.params()[Genie.Router.PARAMS_RESPONSE_KEY] = new_res
  new_res
end


function setstatus!(res::HTTP.Response, status::Int) :: HTTP.Response
  _update_response!(HTTP.Response(status, res.headers, body = res.body))
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
  _update_response!(HTTP.Response(res.status, res.headers, body = body))
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
