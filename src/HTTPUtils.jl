"""
Genie utilities for working over HTTP.
"""
module HTTPUtils

import HTTP


"""
    Base.Dict(req::HTTP.Request) :: Dict{String,String}

Converts a `HTTP.Request` to a `Dict`.
"""
function Base.Dict(req::HTTP.Request) :: Dict{String,String}
  result = Dict{String,String}()
  for (k,v) in Dict(req.headers)
    result[lowercase(string(k))] = lowercase(string(v))
  end

  result
end

end