@testitem "Hello Genie" setup=[GenieTestSetup] begin

  using Genie, HTTP

  message = "Welcome to Genie!"

  route("/hello") do
    message
  end

  server, port = unique_server()

  response = HTTP.get("http://localhost:$port/hello")

  @test response.status == 200
  @test String(response.body) == message

  down()
  sleep(1)
  server = nothing
  port = nothing
end