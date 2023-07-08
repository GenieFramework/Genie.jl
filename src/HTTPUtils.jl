"""
Genie utilities for working over HTTP.
"""
module HTTPUtils

import HTTP, OrderedCollections


"""
    Base.Dict(req::HTTP.Request) :: Dict{String,String}

Converts a `HTTP.Request` to a `Dict`.
"""
function Base.Dict(req::HTTP.Request) :: Base.ImmutableDict{String,String}
  result = Base.ImmutableDict{String,String}()
  for (k,v) in OrderedCollections.LittleDict(req.headers)
    result = Base.ImmutableDict(result, lowercase(string(k)) => lowercase(string(v)))
  end

  result
end

end