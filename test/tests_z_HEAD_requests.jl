# @testitem "HEAD requests" setup=[GenieTestSetup] begin
  @testitem "HEAD requests should be by default handled by GET" setup=[GenieTestSetup] begin
    route("/") do
      "GET request"
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$PORT", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "GET request"

    response = try
      HTTP.request("HEAD", "http://127.0.0.1:$PORT", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == ""
  end;

  @testitem "HEAD requests have no body" setup=[GenieTestSetup] begin
    route("/") do
      "Hello world"
    end

    route("/", method = HEAD) do
      "Hello world"
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$PORT", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "Hello world"

    response = try
      HTTP.request("HEAD", "http://127.0.0.1:$PORT", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end
    @test response.status == 200
    @test isempty(String(response.body)) == true
  end;

  @testitem "HEAD requests should overwrite GET" setup=[GenieTestSetup] begin
    request_method = Ref("")

    route("/", named = :get_root) do
      request_method[] = "GET"
      "GET request"
    end

    route("/", method = "HEAD", named = :head_root) do
      request_method[] = "HEAD"
      "HEAD request"
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$PORT", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test request_method[] == "GET"

    response = try
      HTTP.request("HEAD", "http://127.0.0.1:$PORT", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test request_method[] == "HEAD"
  end;

# end;
