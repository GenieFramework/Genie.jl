@safetestset "HEAD requests" begin
  @safetestset "HEAD requests should be by default handled by GET" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/") do _
      "GET request"
    end

    server = up(port)

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "GET request"

    response = try
      HTTP.request("HEAD", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == ""

    down()
    sleep(1)
    server = nothing
    port = nothing
  end;

  @safetestset "HEAD requests have no body" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/") do _
      "Hello world"
    end

    route("/", method = HEAD) do _
      "Hello world"
    end

    server = up(port; open_browser = false)

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "Hello world"

    response = try
      HTTP.request("HEAD", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end
    @test response.status == 200
    @test isempty(String(response.body)) == true

    down()
    sleep(1)
    server = nothing
    port = nothing
  end;

  @safetestset "HEAD requests should overwrite GET" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    request_method = ""

    route("/", named = :get_root) do _
      request_method = "GET"
      "GET request"
    end

    route("/", method = "HEAD", named = :head_root) do _
      request_method = "HEAD"
      "HEAD request"
    end

    server = up(port)
    sleep(1)

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test request_method == "GET"

    response = try
      HTTP.request("HEAD", "http://127.0.0.1:$port", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test request_method == "HEAD"

    down()
    sleep(1)
    server = nothing
    port = nothing
  end;

end;
