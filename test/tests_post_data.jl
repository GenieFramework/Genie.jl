@testitem "POST form payload" setup=[GenieTestSetup] begin
  using Genie.Router, Genie.Requests

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

  sleep(0)
  start_unique_server()

  response = HTTP.request("POST", "http://localhost:$PORT/", ["Content-Type" => "application/x-www-form-urlencoded"], "greeting=Hello")
  @test response.status == 200
  @test String(response.body) == "Hello"

  response = HTTP.request("POST", "http://localhost:$PORT/", ["Content-Type" => "application/x-www-form-urlencoded"], "greeting=Hey you there")
  @test response.status == 200
  @test String(response.body) == "Hey you there"

  response = HTTP.request("GET", "http://localhost:$PORT/", ["Content-Type" => "application/x-www-form-urlencoded"], "greeting=Hello")
  @test response.status == 200
  @test String(response.body) == "GET"

  response = HTTP.request("POST", "http://localhost:$PORT/data", ["Content-Type" => "application/x-www-form-urlencoded"], "fields%5B%5D=Hey you there&fields%5B%5D=&single=")
  @test response.status == 200
  @test String(response.body) == "Hey you there"

  response = HTTP.request("POST", "http://localhost:$PORT/data", ["Content-Type" => "application/x-www-form-urlencoded"], "fields%5B%5D=1&fields%5B%5D=2&single=3")
  @test response.status == 200
  @test String(response.body) == "123"

  response = HTTP.post("http://localhost:$PORT", [], HTTP.Form(Dict("greeting" => "Hello")))
  @test response.status == 200
  @test String(response.body) == "Hello"

  response = HTTP.post("http://localhost:$PORT", [], HTTP.Form(Dict("greeting" => "Hey you there")))
  @test response.status == 200
  @test String(response.body) == "Hey you there"
end