@testitem "JSON payload correctly identified" setup=[GenieTestSetup] begin

  using Genie, HTTP
  import Genie.Util: fws

  route("/jsonpayload", method = POST) do
    Genie.Requests.jsonpayload()
  end

  route("/jsongreeting", method = POST) do
    Genie.Requests.jsonpayload("greeting")
  end

  response = HTTP.request("POST", "http://localhost:$PORT/jsonpayload",
                  [("Content-Type", "application/json; charset=utf-8")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """Dict{String, Any}("greeting" => "hello")""" |> fws

  response = HTTP.request("POST", "http://localhost:$PORT/jsongreeting",
                  [("Content-Type", "application/json")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """hello""" |> fws

  response = HTTP.request("POST", "http://localhost:$PORT/jsonpayload",
                  [("Content-Type", "application/json")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """Dict{String, Any}("greeting" => "hello")""" |> fws

  response = HTTP.request("POST", "http://localhost:$PORT/jsongreeting",
                  [("Content-Type", "application/json; charset=utf-8")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """hello""" |> fws

  #===#

  response = HTTP.request("POST", "http://localhost:$PORT/jsonpayload",
                  [("Content-Type", "application/vnd.api+json; charset=utf-8")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """Dict{String, Any}("greeting" => "hello")""" |> fws

  response = HTTP.request("POST", "http://localhost:$PORT/jsongreeting",
                  [("Content-Type", "application/vnd.api+json; charset=utf-8")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """hello""" |> fws

  response = HTTP.request("POST", "http://localhost:$PORT/jsonpayload",
                  [("Content-Type", "application/vnd.api+json")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """Dict{String, Any}("greeting" => "hello")""" |> fws

  response = HTTP.request("POST", "http://localhost:$PORT/jsongreeting",
                  [("Content-Type", "application/vnd.api+json")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """hello""" |> fws
end;