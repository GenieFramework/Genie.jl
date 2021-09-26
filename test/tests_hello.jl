@safetestset "Hello Genie" begin

  using Genie, HTTP

  message = "Welcome to Genie!"

  route("/hello") do
    message
  end

  port = nothing
  port = rand(8500:8900)

  up(port)

  response = HTTP.get("http://localhost:$port/hello")

  @test response.status == 200
  @test String(response.body) == message

  down()
  sleep(1)
  server = nothing
  port = nothing
end