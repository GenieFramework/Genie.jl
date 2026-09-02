# @testitem "Routing edge cases" setup=[GenieTestSetup] begin

  @testitem "Emoji routing" setup=[GenieTestSetup] begin
    route("/✔/🧞/♥/❤") do
      "/✔/🧞/♥/❤"
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/✔/🧞/♥/❤")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "/✔/🧞/♥/❤"
  end;

  @testitem "Emoji routing ✔" setup=[GenieTestSetup] begin
    route("/✔") do
      "All good"
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/✔")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "All good"
  end;

  @testitem "Encoded urls é" setup=[GenieTestSetup] begin
    route("/réception") do
      "Meet at réception"
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/réception")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "Meet at réception"
  end;

  @testitem "Emoji routing with params" setup=[GenieTestSetup] begin
    using Genie, Genie.Requests
    route("/:check/:genie/:smallheart/:bigheart") do
      "/$(payload(:check))/$(payload(:genie))/$(payload(:smallheart))/$(payload(:bigheart))"
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/✔/🧞/♥/❤")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "/✔/🧞/♥/❤"
  end;

# end