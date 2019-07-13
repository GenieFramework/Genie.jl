module HTTPUtils

using HTTP

"""
"""
function req_headers_to_dict(req::HTTP.Request) :: Dict{String,String}
  result = Dict{String,String}()
  for (k,v) in Dict(req.headers)
    result[lowercase(string(k))] = lowercase(string(v))
  end

  result
end

end