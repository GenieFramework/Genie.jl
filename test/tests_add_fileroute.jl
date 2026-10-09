@testitem "add_fileroute content-type inference" setup=[GenieTestSetup] begin
  using Genie, Genie.Assets, HTTP

  function serve_and_fetch(filename, content, named)
    basedir = mktempdir()
    ext = splitext(filename)[2]
    type = ext[2:end]
    dir = joinpath(basedir, "assets", type)
    mkpath(dir)
    write(joinpath(dir, filename), content)

    ac = Genie.Assets.AssetsConfig(host = "/", package = "add_fileroute_test", version = "1")
    Genie.Assets.add_fileroute(ac, filename; basedir, named)

    url = "http://127.0.0.1:$PORT" * Genie.Assets.asset_path(ac, type; file = splitext(filename)[1], ext)

    HTTP.request("GET", url)
  end

  @testset "Unrecognized extension falls back to application/octet-stream" begin
    # Regression test: add_fileroute used to build Symbol("*.*") for unrecognized
    # extensions, which isn't a key in Renderer.CONTENT_TYPES, causing a KeyError
    # inside respond() at request time.
    response = serve_and_fetch("hh.bin", "hello", :__test_add_fileroute_binary)

    @test response.status == 200
    @test String(response.body) == "hello"

    content_types = [v for (k, v) in response.headers if lowercase(k) == "content-type"]
    @test content_types == ["application/octet-stream"]
  end

  @testset "Known image/video extensions resolve to a real Content-Type" begin
    # Regression test: add_fileroute used to build Symbol("image/$imagetype") (e.g.
    # Symbol("image/jpeg")), which also isn't a key in CONTENT_TYPES (whose keys are
    # short names like :jpg, :png, :svg) -- every one of these extensions used to
    # KeyError. mov/avi are video, not image, and got their own CONTENT_TYPES entries.
    cases = [
      ("a.jpg",  "image/jpeg"),
      ("a.jpeg", "image/jpeg"),
      ("a.png",  "image/png"),
      ("a.svg",  "image/svg+xml"),
      ("a.gif",  "image/gif"),
      ("a.tif",  "image/tiff"),
      ("a.tiff", "image/tiff"),
      ("a.mov",  "video/quicktime"),
      ("a.avi",  "video/x-msvideo"),
    ]

    for (i, (filename, expected_content_type)) in enumerate(cases)
      response = serve_and_fetch(filename, "data-$i", Symbol("__test_add_fileroute_$i"))

      @test response.status == 200

      content_types = [v for (k, v) in response.headers if lowercase(k) == "content-type"]
      @test content_types == [expected_content_type]
    end
  end

  @testset "cache_control and headers kwargs" begin
    basedir = mktempdir()
    mkpath(joinpath(basedir, "assets", "js"))
    write(joinpath(basedir, "assets", "js", "foo.js"), "console.log(1)")

    ac = Genie.Assets.AssetsConfig(host = "/", package = "add_fileroute_test_cc", version = "1")
    Genie.Assets.add_fileroute(ac, "foo.js"; basedir, named = :__test_add_fileroute_cc,
                                cache_control = "public, max-age=86400", headers = ["X-Foo" => "bar"])

    url = "http://127.0.0.1:$PORT" * Genie.Assets.asset_path(ac, "js"; file = "foo", ext = ".js")
    response = HTTP.request("GET", url)

    @test response.status == 200
    @test Dict(response.headers)["Cache-Control"] == "public, max-age=86400"
    @test Dict(response.headers)["X-Foo"] == "bar"

    content_types = [v for (k, v) in response.headers if lowercase(k) == "content-type"]
    @test content_types == ["application/javascript; charset=utf-8"]
  end

  @testset "default_cache_control() reads GENIE_ASSETS_CACHE_MAXAGE" begin
    delete!(ENV, "GENIE_ASSETS_CACHE_MAXAGE")
    @test Genie.Assets.default_cache_control() === nothing

    ENV["GENIE_ASSETS_CACHE_MAXAGE"] = ""
    @test Genie.Assets.default_cache_control() === nothing

    try
      ENV["GENIE_ASSETS_CACHE_MAXAGE"] = "600"
      @test Genie.Assets.default_cache_control() == "public, max-age=600"
    finally
      delete!(ENV, "GENIE_ASSETS_CACHE_MAXAGE")
    end
  end

  @testset "add_fileroute picks up GENIE_ASSETS_CACHE_MAXAGE when cache_control not given" begin
    basedir = mktempdir()
    mkpath(joinpath(basedir, "assets", "js"))
    write(joinpath(basedir, "assets", "js", "env.js"), "console.log(2)")
    ac = Genie.Assets.AssetsConfig(host = "/", package = "add_fileroute_test_env", version = "1")

    try
      ENV["GENIE_ASSETS_CACHE_MAXAGE"] = "120"
      Genie.Assets.add_fileroute(ac, "env.js"; basedir, named = :__test_add_fileroute_env)

      url = "http://127.0.0.1:$PORT" * Genie.Assets.asset_path(ac, "js"; file = "env", ext = ".js")
      response = HTTP.request("GET", url)

      @test response.status == 200
      @test Dict(response.headers)["Cache-Control"] == "public, max-age=120"
    finally
      delete!(ENV, "GENIE_ASSETS_CACHE_MAXAGE")
    end
  end

  @testset "explicit cache_control overrides GENIE_ASSETS_CACHE_MAXAGE" begin
    basedir = mktempdir()
    mkpath(joinpath(basedir, "assets", "js"))
    write(joinpath(basedir, "assets", "js", "override.js"), "console.log(3)")
    ac = Genie.Assets.AssetsConfig(host = "/", package = "add_fileroute_test_override", version = "1")

    try
      ENV["GENIE_ASSETS_CACHE_MAXAGE"] = "120"
      Genie.Assets.add_fileroute(ac, "override.js"; basedir, named = :__test_add_fileroute_override,
                                  cache_control = "no-store")

      url = "http://127.0.0.1:$PORT" * Genie.Assets.asset_path(ac, "js"; file = "override", ext = ".js")
      response = HTTP.request("GET", url)

      @test response.status == 200
      @test Dict(response.headers)["Cache-Control"] == "no-store"
    finally
      delete!(ENV, "GENIE_ASSETS_CACHE_MAXAGE")
    end
  end
end

@testitem "add_fileroute(route::String, filename; ...) -- literal-path method" setup=[GenieTestSetup] begin
  using Genie, Genie.Assets, HTTP

  @testset "serves the file at the literal route, with content-type inference" begin
    basedir = mktempdir()
    write(joinpath(basedir, "handbook.txt"), "hello world")

    Genie.Assets.add_fileroute("/docs/handbook.txt", "handbook.txt"; basedir, named = :__test_literal_fileroute)

    response = HTTP.request("GET", "http://127.0.0.1:$PORT/docs/handbook.txt")

    @test response.status == 200
    @test String(response.body) == "hello world"
    @test Dict(response.headers)["Content-Type"] == "application/octet-stream"
    @test !haskey(Dict(response.headers), "Cache-Control")
  end

  @testset "default cache_control from GENIE_ASSETS_CACHE_MAXAGE, explicit override wins" begin
    basedir = mktempdir()
    write(joinpath(basedir, "a.js"), "console.log(1)")
    write(joinpath(basedir, "b.js"), "console.log(2)")

    try
      ENV["GENIE_ASSETS_CACHE_MAXAGE"] = "300"

      Genie.Assets.add_fileroute("/lit/a.js", "a.js"; basedir, named = :__test_literal_fileroute_default)
      response_a = HTTP.request("GET", "http://127.0.0.1:$PORT/lit/a.js")
      @test Dict(response_a.headers)["Cache-Control"] == "public, max-age=300"
      @test Dict(response_a.headers)["Content-Type"] == "application/javascript; charset=utf-8"

      Genie.Assets.add_fileroute("/lit/b.js", "b.js"; basedir, named = :__test_literal_fileroute_override,
                                  cache_control = nothing)
      response_b = HTTP.request("GET", "http://127.0.0.1:$PORT/lit/b.js")
      @test !haskey(Dict(response_b.headers), "Cache-Control")
    finally
      delete!(ENV, "GENIE_ASSETS_CACHE_MAXAGE")
    end
  end
end
