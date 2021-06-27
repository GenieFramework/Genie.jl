@safetestset "JSON payload" begin

  using Genie, HTTP
  import Genie.Requests: jsonpayload

  route("/jsonpayload", method = POST) do
    jsonpayload()
  end

  route("/jsontest", method = POST) do
    jsonpayload("test")
  end

  server = up(; open_browser = false)

  response = try
    HTTP.request("POST", "http://localhost:8000/jsonpayload",
                  [("Content-Type", "application/json; charset=utf-8")], """{"greeting":"hello"}""")
  catch ex
    ex.response
  end

  @test response.status == 200
  @test String(response.body) == """Dict{String, Any}("greeting" => "hello")"""

  response = try
    HTTP.request("POST", "http://localhost:8000/jsontest",
                  [("Content-Type", "application/json; charset=utf-8")], """{"test":[1,2,3]}""")
  catch ex
    ex.response
  end

  @test_broken response.status == 200
  @test_broken String(response.body) == """[1,2,3]"""

  down()
  sleep(1)
  server = nothing

end;