@safetestset "POST form payload" begin

  using Genie, HTTP

  route("/") do
    "GET"
  end

  route("/", method = POST) do
    params(:greeting)
  end

  port = nothing
  port = rand(8500:8900)

  up(port; open_browser = false)

  response = HTTP.request("POST", "http://localhost:$port/", ["Content-Type" => "application/x-www-form-urlencoded"], "greeting=Hello")
  @test response.status == 200
  @test String(response.body) == "Hello"

  response = HTTP.request("GET", "http://localhost:$port/", ["Content-Type" => "application/x-www-form-urlencoded"], "greeting=Hello")
  @test response.status == 200
  @test String(response.body) == "GET"

  down()
  sleep(1)
  server = nothing
  port = nothing
end