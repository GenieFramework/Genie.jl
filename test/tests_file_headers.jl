@testitem "file_headers() / GENIE_STATIC_CACHE_MAXAGE" setup=[GenieTestSetup] begin
  using Genie, HTTP

  dir = mktempdir()
  write(joinpath(dir, "test.txt"), "hello")

  @testset "default_static_cache_control()" begin
    delete!(ENV, "GENIE_STATIC_CACHE_MAXAGE")
    @test Genie.Router.default_static_cache_control() === nothing

    ENV["GENIE_STATIC_CACHE_MAXAGE"] = ""
    @test Genie.Router.default_static_cache_control() === nothing

    try
      ENV["GENIE_STATIC_CACHE_MAXAGE"] = "600"
      @test Genie.Router.default_static_cache_control() == "public, max-age=600"
    finally
      delete!(ENV, "GENIE_STATIC_CACHE_MAXAGE")
    end
  end

  @testset "no Cache-Control header when env var unset" begin
    delete!(ENV, "GENIE_STATIC_CACHE_MAXAGE")
    response = Genie.Router.serve_static_file("/test.txt", root = dir)

    @test response.status == 200
    @test String(response.body) == "hello"
    @test !HTTP.hasheader(response, "Cache-Control")
  end

  @testset "Cache-Control set from GENIE_STATIC_CACHE_MAXAGE" begin
    try
      ENV["GENIE_STATIC_CACHE_MAXAGE"] = "600"
      response = Genie.Router.serve_static_file("/test.txt", root = dir)

      @test response.status == 200
      @test HTTP.header(response, "Cache-Control") == "public, max-age=600"
    finally
      delete!(ENV, "GENIE_STATIC_CACHE_MAXAGE")
    end
  end

  @testset "file_headers() returns HTTP.Headers and is read fresh every call (not baked in)" begin
    @test Genie.Router.file_headers(joinpath(dir, "test.txt")) isa HTTP.Headers

    try
      ENV["GENIE_STATIC_CACHE_MAXAGE"] = "111"
      h1 = Genie.Router.file_headers(joinpath(dir, "test.txt"))
      @test HTTP.header(h1, "Cache-Control") == "public, max-age=111"

      ENV["GENIE_STATIC_CACHE_MAXAGE"] = "222"
      h2 = Genie.Router.file_headers(joinpath(dir, "test.txt"))
      @test HTTP.header(h2, "Cache-Control") == "public, max-age=222"
    finally
      delete!(ENV, "GENIE_STATIC_CACHE_MAXAGE")
    end
  end
end
