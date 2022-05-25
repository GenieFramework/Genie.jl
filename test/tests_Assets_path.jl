@safetestset "Assets functionality" begin

  @safetestset "Assets paths" begin
    using Genie, Genie.Assets

    Genie.config.base_path = "/proxy/8000"

    @test Genie.Assets.asset_path("s.js") == "/proxy/8000/assets/js/s.js"
    @test Genie.Assets.asset_path("s.js", host = "") == "/assets/js/s.js"
    @test Genie.Assets.asset_path("s.js", host = "/") == "/assets/js/s.js"
    @test Genie.Assets.asset_path("s.js", host = "//") == "/assets/js/s.js"
    @test Genie.Assets.asset_path("s.js", path = "/") == "/proxy/8000/assets/js/s.js"
    @test Genie.Assets.asset_path("s.js", path = "//") == "/proxy/8000/assets/js/s.js"
    @test Genie.Assets.asset_path("s.js", path = "foo") == "/proxy/8000/assets/js/foo/s.js"
    @test Genie.Assets.asset_path("s.js", path = "foo/bar") == "/proxy/8000/assets/js/foo/bar/s.js"
    @test Genie.Assets.asset_path("s.js", path = "foo/bar/baz") == "/proxy/8000/assets/js/foo/bar/baz/s.js"
    @test Genie.Assets.asset_path("s.js", path = "/foo/bar/baz") == "/proxy/8000/assets/js/foo/bar/baz/s.js"
    @test Genie.Assets.asset_path("s.js", path = "/foo/bar/baz/") == "/proxy/8000/assets/js/foo/bar/baz/s.js"
    @test Genie.Assets.asset_path("s.js", host = "abc", path = "/foo/bar/baz/") == "/abc/assets/js/foo/bar/baz/s.js"
    @test Genie.Assets.asset_path("s.js", host = "abc/def", path = "/foo/bar/baz/") == "/abc/def/assets/js/foo/bar/baz/s.js"
    @test Genie.Assets.asset_path("s.js", host = "/abc/def", path = "/foo/bar/baz/") == "/abc/def/assets/js/foo/bar/baz/s.js"
    @test Genie.Assets.asset_path("s.js", host = "/abc/def/", path = "/foo/bar/baz/") == "/abc/def/assets/js/foo/bar/baz/s.js"

    Genie.config.base_path = "/proxy/8000/"
    @test Genie.Assets.asset_path("s.js", path = "/foo/bar/baz/") == "/proxy/8000/assets/js/foo/bar/baz/s.js"

    Genie.config.base_path = "proxy/8000"
    @test Genie.Assets.asset_path("s.js", path = "/foo/bar/baz/") == "/proxy/8000/assets/js/foo/bar/baz/s.js"
    @test Genie.Assets.asset_path("s.js") == "/proxy/8000/assets/js/s.js"
  end;

end;
