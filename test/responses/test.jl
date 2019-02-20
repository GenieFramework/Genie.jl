using Pkg
pkg"activate ."

using Genie, HTTP
using Genie.Router, Genie.Responses

route("/responses", method = GET) do
  @show getstatus()
  @show getheaders()
  @show getbody()

  setstatus(301)
  setheaders(Dict("X-Foo-Bar"=>"Baz"))
  setheaders(Dict("X-A-B"=>"C", "X-Moo"=>"Cow"))
  setbody("Hello")

  @show getstatus()
  @show getheaders()
  @show getbody()

  getresponse()
end

route("/broken") do
 omg!()
end

Genie.AppServer.startup(verbose = true)

response = HTTP.request("GET", "http://localhost:8000/responses")
@show response

response = HTTP.request("GET", "http://localhost:8000/broken", ["Content-Type"=>"text/plain"])
@show response

exit(0)
