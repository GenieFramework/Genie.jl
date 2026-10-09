@testitem "Setting and getting headers" setup=[GenieTestSetup] begin

  using Genie, HTTP
  using Genie.Router, Genie.Responses

  route("/headers") do
    setheaders("X-Foo-Bar" => "Baz")

    "OK"
  end

  route("/headers", method = OPTIONS) do
    setheaders(["X-Foo-Bar" => "Bazinga", "Access-Control-Allow-Methods" => "GET, POST, OPTIONS"])
    setstatus(200)

    "OOKK"
  end

  sleep(0)

  response = HTTP.request("GET", "http://localhost:$PORT/headers") # unhandled, should get default response
  @test response.status == 200
  @test String(response.body) == "OK"
  @test Dict(response.headers)["X-Foo-Bar"] == "Baz"
  @test get(Dict(response.headers), "Access-Control-Allow-Methods", nothing) == nothing

  response = HTTP.request("OPTIONS", "http://localhost:$PORT/headers") # handled
  @test response.status == 200
  @test String(response.body) == "OOKK"
  @test Dict(response.headers)["X-Foo-Bar"] == "Bazinga"
  @test get(Dict(response.headers), "Access-Control-Allow-Methods", nothing) == "GET, POST, OPTIONS"
end


@testitem "Multiple Set-Cookie headers survive, with and without an Origin (CORS) header" setup=[GenieTestSetup] begin
  # Regression test: Headers.set_access_control_allow_origin! used to build its merged
  # headers via Dict(res.headers)/Dict(app_response.headers), which silently collapsed
  # multiple Set-Cookie headers down to one whenever the request carried an Origin header
  # (routine for fetch/XHR/WebSocket traffic from any SPA) -- on the main request path
  # (every response goes through Headers.set_headers!). A second, subtler bug meant that
  # even after fixing the loss, res.headers got merged in twice whenever the CORS branch
  # ran, double-counting every cookie instead of losing it.

  using Genie, Genie.Router, Genie.Cookies, HTTP

  route("/two-cookies") do
    res = Genie.Router.params(Genie.Router.PARAMS_RESPONSE_KEY, HTTP.Response())
    Genie.Cookies.set!(res, "a", "1"; encrypted = false)
    Genie.Cookies.set!(res, "b", "2"; encrypted = false)

    "ok"
  end

  function set_cookie_values(response)
    sort([v for (k, v) in response.headers if k == "Set-Cookie"])
  end

  @testset "no Origin header" begin
    response = HTTP.request("GET", "http://127.0.0.1:$PORT/two-cookies")
    @test response.status == 200
    @test set_cookie_values(response) == ["a=1", "b=2"]
  end

  @testset "with an Origin header" begin
    old_allowed_origins = Genie.config.cors_allowed_origins
    try
      Genie.config.cors_allowed_origins = ["*"]

      response = HTTP.request("GET", "http://127.0.0.1:$PORT/two-cookies",
                               ["Origin" => "http://example.com"])

      @test response.status == 200
      @test set_cookie_values(response) == ["a=1", "b=2"]  # neither lost nor duplicated
      @test Dict(response.headers)["Access-Control-Allow-Origin"] == "http://example.com"
      @test Dict(response.headers)["Vary"] == "Origin"
    finally
      Genie.config.cors_allowed_origins = old_allowed_origins
    end
  end
end


@testitem "set_access_control_allow_origin! header precedence" setup=[GenieTestSetup] begin
  using Genie, HTTP

  old_allowed_origins = Genie.config.cors_allowed_origins
  old_acao_default = Genie.config.cors_headers["Access-Control-Allow-Origin"]

  try
    Genie.config.cors_allowed_origins = ["*"]
    Genie.config.cors_headers["Access-Control-Allow-Origin"] = "should-not-win"

    req = HTTP.Request("GET", "/", ["Origin" => "http://foo.com"])

    @testset "app_response's own header wins over the cors_headers default" begin
      app_response = HTTP.Response(200, ["Access-Control-Allow-Origin" => "app-set-this"])
      out = Genie.Headers.set_access_control_allow_origin!(req, HTTP.Response(200), app_response)
      @test HTTP.header(out, "Access-Control-Allow-Origin") == "app-set-this"
    end

    @testset "falls back to the computed/allowed origin when app_response doesn't set one" begin
      out = Genie.Headers.set_access_control_allow_origin!(req, HTTP.Response(200), HTTP.Response(200))
      @test HTTP.header(out, "Access-Control-Allow-Origin") == "http://foo.com"
      @test HTTP.header(out, "Vary") == "Origin"
    end

    @testset "no Origin header -> app_response passed through unchanged" begin
      req_no_origin = HTTP.Request("GET", "/")
      app_response = HTTP.Response(200, ["X-Marker" => "1"])
      out = Genie.Headers.set_access_control_allow_origin!(req_no_origin, HTTP.Response(200), app_response)
      @test out === app_response
      @test !HTTP.hasheader(out, "Access-Control-Allow-Origin")
    end
  finally
    Genie.config.cors_allowed_origins = old_allowed_origins
    Genie.config.cors_headers["Access-Control-Allow-Origin"] = old_acao_default
  end
end