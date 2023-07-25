# @safetestset "Testing the Genie.Context" begin

  using Genie, Test, HTTP

  Router.@get("/") do
    "OK"
  end

  @get("/get") do params
    @test params[:route].name == :get_get
    @test params[:route].method == "GET"
    @test params[:route].context == @__MODULE__
    "GET"
  end

  @get("/route") do params
    @test params[:route].name == :get_route
    @test params[:route].method == "GET"
    @test params[:route].context == @__MODULE__
    "GET"
  end

  @get("/getwithparams") do params
    @test params[:route].name == :get_getwithparams
    @test params[:route].method == "GET"
    "GETWITHPARAMS"
  end

  @get("/getwithname", named = :get_is_named) do params
    @test params[:route].name == :get_is_named
    @test params[:route].method == "GET"
    "GETWITHNAME"
  end

  @post("/post") do params
    @test params[:route].name == :post_post
    @test params[:route].method == "POST"
    "POST"
  end

  @put("/put") do params
    @test params[:route].name == :put_put
    @test params[:route].method == "PUT"
    "PUT"
  end

  @delete("/delete") do params
    @test params[:route].name == :delete_delete
    @test params[:route].method == "DELETE"
    "DELETE"
  end

  @patch("/patch") do params
    @test params[:route].name == :patch_patch
    @test params[:route].method == "PATCH"
    "PATCH"
  end

  @options("/options") do params
    @test params[:route].name == :options_options
    @test params[:route].method == "OPTIONS"
    "OPTIONS"
  end

  @head("/head") do params
    @test params[:route].name == :head_head
    @test params[:route].method == "HEAD"
    "HEAD"
  end

  port = nothing
  port = rand(8500:8900)
  up(port; open_browser = false, verbose = true)

  response = HTTP.request("GET", "http://localhost:$port/")
  @test response.status == 200
  @test String(response.body) == "OK"

  response = HTTP.request("GET", "http://localhost:$port/get")
  @test response.status == 200
  @test String(response.body) == "GET"

  response = HTTP.request("GET", "http://localhost:$port/getwithparams")
  @test response.status == 200
  @test String(response.body) == "GETWITHPARAMS"

  response = HTTP.request("GET", "http://localhost:$port/getwithname")
  @test response.status == 200
  @test String(response.body) == "GETWITHNAME"

  response = HTTP.request("POST", "http://localhost:$port/post")
  @test response.status == 200
  @test String(response.body) == "POST"

  response = HTTP.request("PUT", "http://localhost:$port/put")
  @test response.status == 200
  @test String(response.body) == "PUT"

  response = HTTP.request("DELETE", "http://localhost:$port/delete")
  @test response.status == 200
  @test String(response.body) == "DELETE"

  response = HTTP.request("PATCH", "http://localhost:$port/patch")
  @test response.status == 200
  @test String(response.body) == "PATCH"

  response = HTTP.request("OPTIONS", "http://localhost:$port/options")
  @test response.status == 200
  @test String(response.body) == "OPTIONS"

  response = HTTP.request("HEAD", "http://localhost:$port/head")
  @test response.status == 200
  @test String(response.body) == ""

  down()
  sleep(1)
  server = nothing
  port = nothing

# end