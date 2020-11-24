@safetestset "HEAD requests" begin
  @safetestset "HEAD requests have no body" begin
    using Genie
    using HTTP

    route("/") do
      "Hello world"
    end

    route("/", method = HEAD) do
      "Hello world"
    end

    Genie.up(; open_browser = false)

    response = try
      HTTP.request("GET", "http://127.0.0.1:8000", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "Hello world"

    response = try
      HTTP.request("HEAD", "http://127.0.0.1:8000", ["Content-Type" => "text/html"])
    catch ex
      ex.response
    end
    @test response.status == 200
    @test isempty(String(response.body)) == true

    down()
  end;
end;
