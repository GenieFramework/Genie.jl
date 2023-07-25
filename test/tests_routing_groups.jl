# @safetestset "Testing the Genie.Context" begin

  using Genie, Test, HTTP

  group([
      @get("/:user/info", (params) -> params[:user] * " info"),
      @post("/:user/create", (params) -> params[:user] * " create"),
  ],
  prefix = "/api/v1",
  postfix = "/json")

  port = nothing
  port = rand(8500:8900)
  up(port; open_browser = false, verbose = true)

  response = HTTP.request("GET", "http://localhost:$port/api/v1/1000/info/json")
  @test response.status == 200
  @test String(response.body) == "1000 info"

  response = HTTP.request("POST", "http://localhost:$port/api/v1/1000/create/json")
  @test response.status == 200
  @test String(response.body) == "1000 create"

  group([
      @get("/:user/info", (params) -> params[:user] * " info"),
      @post("/:user/create", (params) -> params[:user] * " create"),
  ],
  prefix = "/api/v2",
  postfix = "/text")

  response = HTTP.request("GET", "http://localhost:$port/api/v2/1000/info/text")
  @test response.status == 200
  @test String(response.body) == "1000 info"

  response = HTTP.request("POST", "http://localhost:$port/api/v2/1000/create/text")
  @test response.status == 200
  @test String(response.body) == "1000 create"

  response = HTTP.request("GET", "http://localhost:$port/api/v1/1000/info/json"; status_exception = false)
  @test response.status == 404

  response = HTTP.request("POST", "http://localhost:$port/api/v1/1000/create/json"; status_exception = false)
  @test response.status == 404

  rg = RoutesGroup([
      @get("/:user/info", (params) -> params[:user] * " info"),
      @post("/:user/create", (params) -> params[:user] * " create"),
  ],
  prefix = "/api/v3",
  postfix = "/html")

  @test rg.prefix == "/api/v3"
  @test rg.postfix == "/html"

  response = HTTP.request("GET", "http://localhost:$port/api/v3/1000/info/html"; status_exception = false)
  @test response.status == 404

  response = HTTP.request("POST", "http://localhost:$port/api/v3/1000/create/html"; status_exception = false)
  @test response.status == 404

  rg |> routes

  response = HTTP.request("GET", "http://localhost:$port/api/v3/1000/info/html"; status_exception = false)
  @test response.status == 200
  @test String(response.body) == "1000 info"

  response = HTTP.request("POST", "http://localhost:$port/api/v3/1000/create/html"; status_exception = false)
  @test response.status == 200
  @test String(response.body) == "1000 create"

  rg.prefix = "/private"
  rg.postfix = "/cache"

  response = HTTP.request("GET", "http://localhost:$port/api/v3/1000/info/html"; status_exception = false)
  @test response.status == 200
  @test String(response.body) == "1000 info"

  response = HTTP.request("POST", "http://localhost:$port/api/v3/1000/create/html"; status_exception = false)
  @test response.status == 200
  @test String(response.body) == "1000 create"

  response = HTTP.request("GET", "http://localhost:$port/private/api/v3/1000/info/html"; status_exception = false)
  @test response.status == 404

  response = HTTP.request("POST", "http://localhost:$port/private/api/v3/1000/create/html"; status_exception = false)
  @test response.status == 404

  rg |> routes

  response = HTTP.request("GET", "http://localhost:$port/private/api/v3/1000/info/html/cache"; status_exception = false)
  @test response.status == 200
  @test String(response.body) == "1000 info"

  response = HTTP.request("POST", "http://localhost:$port/private/api/v3/1000/create/html/cache"; status_exception = false)
  @test response.status == 200
  @test String(response.body) == "1000 create"

  response = HTTP.request("GET", "http://localhost:$port/api/v3/1000/info/html"; status_exception = false)
  @test response.status == 404

  response = HTTP.request("POST", "http://localhost:$port/api/v3/1000/create/html"; status_exception = false)
  @test response.status == 404

  down()
  sleep(1)
  server = nothing
  port = nothing

# end