using Pkg
pkg"activate ."

using Genie, HTTP
using Genie.Router, Genie.Responses

route("/headers") do
  setheaders("X-Foo-Bar" => "Baz")

  "Foo bar baz"
end
route("/headers", method = OPTIONS) do
  setheaders(["X-Foo-Bar" => "Baz", "Access-Control-Allow-Methods" => "GET, POST, OPTIONS"])
  setstatus(200)
end

Genie.AppServer.startup(verbose = true)

response = HTTP.request("GET", "http://localhost:8000/headers") # unhandled, should get default response
@show response

response = HTTP.request("OPTIONS", "http://localhost:8000/headers") # handled
@show response

exit(0)
