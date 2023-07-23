"""
Genie utilities for working over HTTP.
"""
module HTTPUtils

import HTTP, OrderedCollections


"""
    Base.Dict(req::HTTP.Request) :: Dict{String,String}

Converts a `HTTP.Request` to a `Dict`.
"""
function Base.Dict(req::HTTP.Request) :: OrderedCollections.LittleDict{String,String}
  result = OrderedCollections.LittleDict{String,String}()
  for (k,v) in OrderedCollections.LittleDict(req.headers)
    result[lowercase(string(k))] = lowercase(string(v))
  end

  result
end

end