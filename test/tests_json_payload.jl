@safetestset "JSON payload" begin

  using Genie, HTTP
  import Genie.Util: fws

  down()
  
  route("/jsonpayload", method = POST) do
    Genie.Requests.jsonpayload()
  end

  route("/jsontest", method = POST) do
    Genie.Requests.jsonpayload("test")
  end

  port = nothing
  port = rand(8500:8900)

  server = up(port)

  response = HTTP.request("POST", "http://localhost:$port/jsonpayload",
                  [("Content-Type", "application/json; charset=utf-8")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """Dict{String, Any}("greeting" => "hello")""" |> fws

  response = HTTP.request("POST", "http://localhost:$port/jsontest",
                  [("Content-Type", "application/json; charset=utf-8")], """{"test":[1,2,3]}""")

  @test response.status == 200
  @test String(response.body) == "[1, 2, 3]"

  route("/json-error", method = POST) do
    error("500, sorry")
  end

  @test_throws HTTP.ExceptionRequest.StatusError HTTP.request("POST", "http://localhost:$port/json-error", [("Content-Type", "application/json; charset=utf-8")], """{"greeting":"hello"}""")

  down()
  sleep(1)
  server = nothing
  port = nothing
end;