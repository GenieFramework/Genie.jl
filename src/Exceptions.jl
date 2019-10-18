module Exceptions

using Revise
using Genie
using HTTP

export ExceptionalResponse, RuntimeException

struct ExceptionalResponse <: Exception
  response::HTTP.Response
end

function Base.show(io::IO, ex::ExceptionalResponse)
  print(io, "ExceptionalResponseException: $(ex.response.status) - $(Dict(ex.response.headers))")
end

###

struct RuntimeException <: Exception
  message::String
  info::String
  code::Int
  ex::Union{Nothing,Exception}
end

RuntimeException(message::String, code::Int) = RuntimeException(message, "", code, nothing)
RuntimeException(message::String, info::String, code::Int) = RuntimeException(message, info, code, nothing)

function Base.show(io::IO, ex::RuntimeException)
  print(io, "RuntimeException: $(ex.code) - $(ex.info) - $(ex.message)")
end

###

struct InternalServerErrorException <: Exception
end

###

struct PageNotFoundException <: Exception
end

end