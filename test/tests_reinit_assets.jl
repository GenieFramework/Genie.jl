@testitem "reinit_assets!()" setup=[GenieTestSetup] begin
  using Genie, Genie.Assets, HTTP

  module ReinitAssetsTestPkg
    using Genie, Genie.Assets

    const assets_config = Genie.Assets.AssetsConfig(host = "/", package = "reinit_assets_test_pkg", version = "1")
    const BASEDIR = Ref{String}("")

    function __init__()
      BASEDIR[] == "" && return nothing
      Genie.Assets.add_fileroute(assets_config, "widget.js"; basedir = BASEDIR[])
    end
  end

  dir = mktempdir()
  mkpath(joinpath(dir, "assets", "js"))
  write(joinpath(dir, "assets", "js", "widget.js"), "console.log('widget')")
  ReinitAssetsTestPkg.BASEDIR[] = dir

  url = "http://127.0.0.1:$PORT" * Genie.Assets.asset_path(ReinitAssetsTestPkg.assets_config, "js"; file = "widget", ext = ".js")

  @testset "re-running __init__() picks up a changed GENIE_ASSETS_CACHE_MAXAGE" begin
    try
      ENV["GENIE_ASSETS_CACHE_MAXAGE"] = "100"
      Genie.Assets.reinit_assets!([ReinitAssetsTestPkg])
      response1 = HTTP.request("GET", url)
      @test Dict(response1.headers)["Cache-Control"] == "public, max-age=100"

      ENV["GENIE_ASSETS_CACHE_MAXAGE"] = "999"
      Genie.Assets.reinit_assets!([ReinitAssetsTestPkg])
      response2 = HTTP.request("GET", url)
      @test Dict(response2.headers)["Cache-Control"] == "public, max-age=999"
    finally
      delete!(ENV, "GENIE_ASSETS_CACHE_MAXAGE")
    end
  end

  @testset "cache_maxage kwarg sets the env var as a convenience" begin
    try
      Genie.Assets.reinit_assets!([ReinitAssetsTestPkg]; cache_maxage = 7200)
      @test ENV["GENIE_ASSETS_CACHE_MAXAGE"] == "7200"

      response = HTTP.request("GET", url)
      @test Dict(response.headers)["Cache-Control"] == "public, max-age=7200"
    finally
      delete!(ENV, "GENIE_ASSETS_CACHE_MAXAGE")
    end
  end

  @testset "re-running multiple times doesn't accumulate duplicate routes" begin
    count_before = length(Genie.Router.named_routes())

    Genie.Assets.reinit_assets!([ReinitAssetsTestPkg]; cache_maxage = 1)
    Genie.Assets.reinit_assets!([ReinitAssetsTestPkg]; cache_maxage = 2)
    Genie.Assets.reinit_assets!([ReinitAssetsTestPkg]; cache_maxage = 3)

    count_after = length(Genie.Router.named_routes())

    try
      @test count_after == count_before

      response = HTTP.request("GET", url)
      @test response.status == 200
      @test Dict(response.headers)["Cache-Control"] == "public, max-age=3"
    finally
      delete!(ENV, "GENIE_ASSETS_CACHE_MAXAGE")
    end
  end

  @testset "Genie itself is safe to pass (its __init__ doesn't register assets)" begin
    @test Genie.Assets.reinit_assets!([Genie]) === nothing
  end
end
