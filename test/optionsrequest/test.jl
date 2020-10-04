using Pkg
Pkg.activate(".")

using Genie, HTTP
using Genie.Router

route("/options", method = OPTIONS) do
  push!(@params(:RESPONSE).headers, "X-Foo-Bar"=>"Baz")
end
Genie.AppServer.startup(; open_browser = false, verbose = true)

response = HTTP.request("OPTIONS", "http://localhost:8000") # unhandled, should get default response
@show response

response = HTTP.request("OPTIONS", "http://localhost:8000/options") # handled
@show response

exit(0)
