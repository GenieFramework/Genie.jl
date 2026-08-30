# @testitem "Special chars in GET params (query)" begin
  @testitem "<a+b> should be <a b>" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/") do
      params(:x)
    end

    server = up(port)
    client = HTTP.Client()

    response = try
      HTTP.request(client, "GET", "http://127.0.0.1:$port/?x=foo+bar")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "foo bar"

    down()
    sleep(1)
    server = nothing
    port = nothing
  end;

  @testitem "<a%20b> should be <a b>" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/") do
      params(:x)
    end

    server = up(port)
    client = HTTP.Client()

    response = try
      HTTP.request(client, "GET", "http://127.0.0.1:$port/?x=foo%20bar")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "foo bar"

    down()
    sleep(1)
    server = nothing
    port = nothing
  end;

  @testitem "<a%2Bb> should be <a+b>" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/") do
      params(:x)
    end

    server = up(port)
    client = HTTP.Client()

    response = try
      HTTP.request(client, "GET", "http://127.0.0.1:$port/?x=foo%2Bbar")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "foo+bar"

    down()
    sleep(1)
    server = nothing
    port = nothing
  end;

  @testitem "emoji support" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/") do
      params(:x)
    end

    server = up(port)
    client = HTTP.Client()

    response = try
      HTTP.request(client, "GET", "http://127.0.0.1:$port/?x=✔+🧞+♥")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "✔ 🧞 ♥"

    down()
    sleep(1)
    server = nothing
    port = nothing
  end;

# end