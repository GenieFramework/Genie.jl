module Exceptions

using Genie
using HTTP

export ExceptionalResponse

struct ExceptionalResponse <: Exception
  response::HTTP.Response
end

function Base.show(io::IO, ex::ExceptionalResponse)
  print(io, "ExceptionalResponseException: $(ex.response.status) - $(Dict(ex.response.headers))")
end

end