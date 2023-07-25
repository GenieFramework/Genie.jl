@safetestset "Testing the Genie.Context" begin

  using Genie, HTTP
  using Genie.Context, Genie.Input
  using Random

  # check defaults
  p = Params()
  @test typeof(p) == Params
  @test typeof(p[:request]) == HTTP.Request
  @test typeof(p[:response]) == HTTP.Response
  @test p[:post] == OrderedCollections.LittleDict{Symbol,Any}()
  @test p[:query] == OrderedCollections.LittleDict{Symbol,Any}()
  @test p[:files] == OrderedCollections.LittleDict{String,HttpFile}()
  @test typeof(p[:wsclient]) == Nothing
  @test typeof(p[:wtclient]) == Nothing
  @test typeof(p[:json]) == Nothing
  @test p[:raw] == ""
  @test typeof(p[:route]) == Nothing
  @test typeof(p[:channel]) == Nothing
  @test typeof(p[:mime]) == Nothing

  # check API
  @test Dict(p) == p.collection
  @test p[:request] == p.collection[:request]
  @test p(:request) == p.collection[:request]
  @test keys(p) == keys(p.collection)
  @test values(p) == values(p.collection)
  @test haskey(p, :request) == haskey(p.collection, :request)
  @test get(p, :testkey, "nothere") == get(p.collection, :testkey, "nothere") == "nothere"
  @test get!(p, :testkey, "default") == p.collection[:testkey] == "default"
  @test params(p, :testkey) == p.collection[:testkey]
  @test p(:testkey) == p.collection[:testkey]
  @test p(:testkey, "value") == p.collection[:testkey] == "value"

  route("/noparams") do
    "OK"
  end

  route("/noparamserror") do
    params[:foo] # 500 error
  end

  route("/params") do params
    params[:route].method
  end

  route("/hooktest") do params
    params[:hooktest]
  end

  hookstr = randstring(10)
  function hooktest(req, res, params)
    params[:hooktest] = hookstr
    req, res, params
  end

  hooktest in Genie.Router.pre_match_hooks || push!(Genie.Router.pre_match_hooks, hooktest)

  port = nothing
  port = rand(8500:8900)

  up(port; open_browser = false, verbose = true)

  response = HTTP.request("GET", "http://localhost:$port/noparams")
  @test response.status == 200
  @test String(response.body) == "OK"

  response = HTTP.request("GET", "http://localhost:$port/noparamserror"; status_exception = false)
  @test response.status == 500

  response = HTTP.request("GET", "http://localhost:$port/params")
  @test response.status == 200
  @test String(response.body) == "GET"

  response = HTTP.request("GET", "http://localhost:$port/hooktest")
  @test response.status == 200
  @test String(response.body) == hookstr

  down()
  sleep(1)
  server = nothing
  port = nothing
end