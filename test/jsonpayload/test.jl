using Pkg
pkg"activate ."

using Genie, HTTP
import Genie.Router: route, POST, @params

route("/jsonpayload", method = POST) do
  @show @params(:JSON_PAYLOAD)
end
Genie.AppServer.startup()

HTTP.request("POST", "http://localhost:8000/jsonpayload", [("Content-Type", "application/json; charset=utf-8")], """{"greeting":"hello"}""")
HTTP.request("POST", "http://localhost:8000/jsonpayload", [("Content-Type", "application/json")], """{"greeting":"hello"}""")

exit(0)
