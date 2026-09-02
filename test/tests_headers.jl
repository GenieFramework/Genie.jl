@testitem "Setting and getting headers" setup=[GenieTestSetup] begin

  using Genie, HTTP
  using Genie.Router, Genie.Responses

  route("/headers") do
    setheaders("X-Foo-Bar" => "Baz")

    "OK"
  end

  route("/headers", method = OPTIONS) do
    setheaders(["X-Foo-Bar" => "Bazinga", "Access-Control-Allow-Methods" => "GET, POST, OPTIONS"])
    setstatus(200)

    "OOKK"
  end

  sleep(0)

  response = HTTP.request("GET", "http://localhost:$PORT/headers") # unhandled, should get default response
  @test response.status == 200
  @test String(response.body) == "OK"
  @test Dict(response.headers)["X-Foo-Bar"] == "Baz"
  @test get(Dict(response.headers), "Access-Control-Allow-Methods", nothing) == nothing

  response = HTTP.request("OPTIONS", "http://localhost:$PORT/headers") # handled
  @test response.status == 200
  @test String(response.body) == "OOKK"
  @test Dict(response.headers)["X-Foo-Bar"] == "Bazinga"
  @test get(Dict(response.headers), "Access-Control-Allow-Methods", nothing) == "GET, POST, OPTIONS"
end