@safetestset "POST form payload" begin

  using Genie, HTTP, Genie.Router, Genie.Requests

  route("/") do
    "GET"
  end

  route("/", method = POST) do
    params(:greeting)
  end

  route("/data", method = POST) do
    fields = postpayload(Symbol("fields[]"))
    fields[1] * fields[2] * postpayload(:single)
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

  response = HTTP.request("POST", "http://localhost:$port/data", ["Content-Type" => "application/x-www-form-urlencoded"], "fields%5B%5D=1&fields%5B%5D=2&single=3")
  @test response.status == 200
  @test String(response.body) == "123"

  down()
  sleep(1)
  server = nothing
  port = nothing
end