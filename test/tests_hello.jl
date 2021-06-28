@safetestset "Hello Genie" begin

  using Genie, HTTP

  message = "Welcome to Genie!"

  route("/hello") do
    message
  end

  port = rand(8500:8900)

  up(port; open_browser = false)

  response = HTTP.get("http://localhost:$port/hello")

  @test response.status == 200
  @test String(response.body) == message

  down()
  sleep(1)
  server = nothing

end