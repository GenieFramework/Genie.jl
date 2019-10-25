module Exceptions

import Revise
import Genie
import HTTP

export ExceptionalResponse, RuntimeException, InternalServerException, NotFoundException

struct ExceptionalResponse <: Exception
  response::HTTP.Response
end

Base.show(io::IO, ex::ExceptionalResponse) = print(io, "ExceptionalResponseException: $(ex.response.status) - $(Dict(ex.response.headers))")

###

struct RuntimeException <: Exception
  message::String
  info::String
  code::Int
  ex::Union{Nothing,Exception}
end

RuntimeException(message::String, code::Int) = RuntimeException(message, "", code, nothing)
RuntimeException(message::String, info::String, code::Int) = RuntimeException(message, info, code, nothing)

Base.show(io::IO, ex::RuntimeException) = print(io, "RuntimeException: $(ex.code) - $(ex.info) - $(ex.message)")

###

struct InternalServerException <: Exception
  message::String
  info::String
  code::Int
end

InternalServerException(message::String) = InternalServerException(message, "", 500)
InternalServerException() = InternalServerException("Internal Server Error")

###

struct NotFoundException <: Exception
  message::String
  info::String
  code::Int
  resource::String
end

NotFoundException(resource::String) = NotFoundException("$resource can not be found", "", 404, resource)
NotFoundException() = NotFoundException("")

end