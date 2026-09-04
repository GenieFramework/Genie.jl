@testitem "OPTIONS requests" setup=[GenieTestSetup] begin

  using Genie, HTTP

  route("/options", method = OPTIONS) do
    push!(params(:RESPONSE).headers, "X-Foo-Bar" => "Baz")
  end

  response = HTTP.request("OPTIONS", "http://localhost:$PORT") # unhandled, should get default response
  @test response.status == 200
  @test get(Dict(response.headers), "X-Foo-Bar", nothing) === nothing

  response = HTTP.request("OPTIONS", "http://localhost:$PORT/options") # handled
  @test response.status == 200
  @test get(Dict(response.headers), "X-Foo-Bar", nothing) == "Baz"
end