using Pkg
Pkg.activate(".")

using Genie, HTTP
import Genie.Router: route, POST, @params
import Genie.Requests: jsonpayload

route("/jsonpayload", method = POST) do
  @show @params(:JSON_PAYLOAD)
end

route("/jsontest", method = POST) do
    json_request = jsonpayload()
    json_request["test"]
end

Genie.AppServer.startup()

HTTP.request("POST", "http://localhost:8000/jsonpayload", [("Content-Type", "application/json; charset=utf-8")], """{"greeting":"hello"}""")
HTTP.request("POST", "http://localhost:8000/jsonpayload", [("Content-Type", "application/json")], """{"greeting":"hello"}""")
HTTP.request("POST", "http://localhost:8000/jsontest", [("Content-Type", "application/json")], """{"test": [1,2,3]}""")

exit(0)
