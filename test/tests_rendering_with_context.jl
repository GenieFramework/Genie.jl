@safetestset "Testing the Genie.Context" begin

  using Genie, HTTP
  using Genie.Context, Genie.Renderer.Html, Genie.Renderer.Json

  port = nothing
  port = rand(8500:8900)
  up(port; open_browser = false, verbose = true)

  route("/nada") do params
    html("OK")
  end

  response = HTTP.request("GET", "http://localhost:$port/nada")
  @test response.status == 200
  @test Dict(response.headers)["Content-Type"] == "text/html; charset=utf-8"


  params = Params()
  params[:response].status = 201
  response = html("OK"; params)
  @test response.status == 201
  @test Dict(response.headers)["Content-Type"] == "text/html; charset=utf-8"


  params = Params()
  params[:response].status = 201
  response = json("OK"; params)

  @test response.status == 201
  @test Dict(response.headers)["Content-Type"] == "application/json; charset=utf-8"


  route("/contenttype") do params
    push!(params[:response].headers, "Content-Type" => "text/plain")
    html("OK"; params)
  end

  response = HTTP.request("GET", "http://localhost:$port/contenttype")
  @test response.status == 200
  @test Dict(response.headers)["Content-Type"] == "text/plain"

  down()
  sleep(1)
  server = nothing
  port = nothing
end