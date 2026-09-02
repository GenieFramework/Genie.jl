# @testitem "Special chars in GET params (query)" setup=[GenieTestSetup] begin
  @testitem "<a+b> should be <a b>" setup=[GenieTestSetup] begin
    route("/") do
      params(:x)
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/?x=foo+bar")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "foo bar"
  end;

  @testitem "<a%20b> should be <a b>" setup=[GenieTestSetup] begin
    route("/") do
      params(:x)
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/?x=foo%20bar")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "foo bar"
  end;

  @testitem "<a%2Bb> should be <a+b>" setup=[GenieTestSetup] begin
    route("/") do
      params(:x)
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/?x=foo%2Bbar")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "foo+bar"
  end;

  @testitem "emoji support" setup=[GenieTestSetup] begin
    route("/") do
      params(:x)
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/?x=✔+🧞+♥")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "✔ 🧞 ♥"
  end;

# end