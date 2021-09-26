@safetestset "OPTIONS requests" begin

  using Genie, HTTP

  route("/options", method = OPTIONS) do
    push!(params(:RESPONSE).headers, "X-Foo-Bar" => "Baz")
  end

  port = nothing
  port = rand(8500:8900)

  server = up(port)
  sleep(1)

  response = HTTP.request("OPTIONS", "http://localhost:$port") # unhandled, should get default response
  @test response.status == 200
  @test get(Dict(response.headers), "X-Foo-Bar", nothing) == nothing

  response = HTTP.request("OPTIONS", "http://localhost:$port/options") # handled
  @test response.status == 200
  @test get(Dict(response.headers), "X-Foo-Bar", nothing) == "Baz"

  down()
  sleep(1)
  server = nothing
  port = nothing
end