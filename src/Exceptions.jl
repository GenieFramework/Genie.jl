module Exceptions

import Genie
import HTTP

export ExceptionalResponse, RuntimeException, InternalServerException, NotFoundException, FileExistsException


"""
    struct ExceptionalResponse <: Exception

A type of exception which wraps an HTTP Response object.
The thrown exception will propagate until it is caught up the app stack or ultimately by Genie
and the wrapped response is sent to the client.

### Example
If the user is not authenticated, an `ExceptionalResponse` is thrown - if the exception is not caught
in the app's stack, Genie will catch it and return the wrapped `Response` object, forcing an HTTP redirect to the login page.

```julia
isauthenticated() || throw(ExceptionalResponse(redirect(:show_login)))
```
"""
struct ExceptionalResponse <: Exception
  response::HTTP.Response
end
function ExceptionalResponse(status, headers, body)
  HTTP.Response(status, headers, body) |> ExceptionalResponse
end

Base.show(io::IO, ex::ExceptionalResponse) = print(io, "ExceptionalResponseException: $(ex.response.status) - $(Dict(ex.response.headers))")

###


"""
    RuntimeException

Represents an unexpected and unhandled runtime exceptions. An error event will be logged and the
exception will be sent to the client, depending on the environment
(the error stack is dumped by default in dev mode or an error message is displayed in production).

It allows defining custom error message and info, as well as an error code, in addition to the exception object.

# Arguments
- `message::String`
- `info::String`
- `code::Int`
- `ex::Union{Nothing,Exception}`
"""
struct RuntimeException <: Exception
  message::String
  info::String
  code::Int
  ex::Union{Nothing,Exception}
end


"""
    RuntimeException(message::String, code::Int)

`RuntimeException` constructor using `message` and `code`.
"""
RuntimeException(message::String, code::Int) = RuntimeException(message, "", code, nothing)


"""
    RuntimeException(message::String, info::String, code::Int)

`RuntimeException` constructor using `message`, `info` and `code`.
"""
RuntimeException(message::String, info::String, code::Int) = RuntimeException(message, info, code, nothing)


"""
    Base.show(io::IO, ex::RuntimeException)

Custom printing of `RuntimeException`
"""
Base.show(io::IO, ex::RuntimeException) = print(io, "RuntimeException: $(ex.code) - $(ex.info) - $(ex.message)")

###

"""
    struct InternalServerException <: Exception

Dedicated exception type for server side exceptions. Results in a 500 error by default.

# Arguments
- `message::String`
- `info::String`
- `code::Int`
"""
struct InternalServerException <: Exception
  message::String
  info::String
  code::Int
end


"""
    InternalServerException(message::String)

External `InternalServerException` constructor accepting a custom message.
"""
InternalServerException(message::String) = InternalServerException(message, "", 500)


"""
    InternalServerException()

External `InternalServerException` using default values.
"""
InternalServerException() = InternalServerException("Internal Server Error")

###


"""
    struct NotFoundException <: Exception

Specialized exception representing a not found resources. Results in a 404 response being sent to the client.

# Arguments
- `message::String`
- `info::String`
- `code::Int`
- `resource::String`
"""
struct NotFoundException <: Exception
  message::String
  info::String
  code::Int
  resource::String
end


"""
    NotFoundException(resource::String)

External constructor allowing to pass the name of the not found resource.
"""
NotFoundException(resource::String) = NotFoundException("$resource can not be found", "", 404, resource)


"""
    NotFoundException()

External constructor using default arguments.
"""
NotFoundException() = NotFoundException("")

###


"""
    struct FileExistsException <: Exception

Custom exception type for signaling that the requested file already exists.
"""
struct FileExistsException <: Exception
  path::String
end


"""
    Base.show(io::IO, ex::FileExistsException)

Custom printing for `FileExistsException`
"""
Base.show(io::IO, ex::FileExistsException) = print(io, "FileExistsException: $(ex.path)")

end
