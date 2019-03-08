module Requests

using Genie, Genie.Router
using HTTP

export jsonpayload, rawpayload, filespayload, postpayload, getpayload, getrequest

function jsonpayload()
  @params(Genie.PARAMS_JSON_PAYLOAD)
end

function rawpayload()
  @params(Genie.PARAMS_RAW_PAYLOAD)
end

function filespayload()
  @params(Genie.PARAMS_FILES)
end
function filespayload(filename::String)
  @params(Genie.PARAMS_FILES)[filename]
end

function postpayload()
  @params(Genie.PARAMS_POST_KEY)
end

function getpayload()
  @params(Genie.PARAMS_GET_KEY)
end

function getrequest()
  @params(Genie.PARAMS_REQUEST_KEY)
end

end
