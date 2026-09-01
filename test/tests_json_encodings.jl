@testitem "JSON payload correctly identified" setup=[GenieTestSetup] begin

  using Genie, HTTP
  import Genie.Util: fws

  route("/jsonpayload", method = POST) do
    Genie.Requests.jsonpayload()
  end

  route("/jsongreeting", method = POST) do
    Genie.Requests.jsonpayload("greeting")
  end

  server, port = unique_server()

  response = HTTP.request("POST", "http://localhost:$port/jsonpayload",
                  [("Content-Type", "application/json; charset=utf-8")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """Dict{String, Any}("greeting" => "hello")""" |> fws

  response = HTTP.request("POST", "http://localhost:$port/jsongreeting",
                  [("Content-Type", "application/json")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """hello""" |> fws

  response = HTTP.request("POST", "http://localhost:$port/jsonpayload",
                  [("Content-Type", "application/json")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """Dict{String, Any}("greeting" => "hello")""" |> fws

  response = HTTP.request("POST", "http://localhost:$port/jsongreeting",
                  [("Content-Type", "application/json; charset=utf-8")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """hello""" |> fws

  #===#

  response = HTTP.request("POST", "http://localhost:$port/jsonpayload",
                  [("Content-Type", "application/vnd.api+json; charset=utf-8")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """Dict{String, Any}("greeting" => "hello")""" |> fws

  response = HTTP.request("POST", "http://localhost:$port/jsongreeting",
                  [("Content-Type", "application/vnd.api+json; charset=utf-8")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """hello""" |> fws

  response = HTTP.request("POST", "http://localhost:$port/jsonpayload",
                  [("Content-Type", "application/vnd.api+json")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """Dict{String, Any}("greeting" => "hello")""" |> fws

  response = HTTP.request("POST", "http://localhost:$port/jsongreeting",
                  [("Content-Type", "application/vnd.api+json")], """{"greeting":"hello"}""")

  @test response.status == 200
  @test String(response.body) |> fws == """hello""" |> fws

  down()
  sleep(1)
  server = nothing
  port = nothing
end;