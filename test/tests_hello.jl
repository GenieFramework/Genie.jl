@testitem "Hello Genie" setup=[GenieTestSetup] begin

  using Genie, HTTP

  message = "Welcome to Genie!"

  route("/hello") do
    message
  end

  response = HTTP.get("http://localhost:$PORT/hello")

  @test response.status == 200
  @test String(response.body) == message
end