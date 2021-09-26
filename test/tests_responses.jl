@safetestset "Responses" begin

  using Genie, HTTP, Genie.Responses

  route("/responses", method = GET) do
    setstatus(301)
    setheaders(Dict("X-Foo-Bar" => "Baz"))
    setheaders(Dict("X-A-B" => "C", "X-Moo" => "Cow"))
    setbody("Hello")
  end

  route("/broken") do
    omg!()
  end

  port = rand(8500:8900)

  server = up(port)

  response = HTTP.request("GET", "http://localhost:$port/responses")
  @test response.status == 301
  @test Dict(response.headers)["X-Foo-Bar"] == "Baz"
  @test Dict(response.headers)["X-A-B"] == "C"
  @test Dict(response.headers)["X-Moo"] == "Cow"
  @test String(response.body) == "Hello"

  @test_throws HTTP.ExceptionRequest.StatusError HTTP.request("GET", "http://localhost:$port/broken", ["Content-Type"=>"text/plain"])

  down(server)
  slepp(1)
  server = nothing
end