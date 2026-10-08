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
end
