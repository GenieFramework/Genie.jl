using Pkg
Pkg.activate(".")

using Genie, HTTP
import Genie.Router: route, POST, @params
import Genie.Requests: jsonpayload

route("/json-error", method = POST) do
  error("500, sorry")
end

Genie.AppServer.startup()

@test_throws HTTP.ExceptionRequest.StatusError HTTP.request("POST", "http://localhost:8000/json-error", [("Content-Type", "application/json; charset=utf-8")], """{"greeting":"hello"}""")

exit(0)
