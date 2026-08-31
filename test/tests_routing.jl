# @testitem "Routing edge cases" setup=[GenieTestSetup] begin

  @testitem "Emoji routing" setup=[GenieTestSetup] begin
    route("/✔/🧞/♥/❤") do
      "/✔/🧞/♥/❤"
    end

    server, port = unique_server()

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/✔/🧞/♥/❤")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "/✔/🧞/♥/❤"

    down()
    sleep(1)
    server = nothing
  end;

  @testitem "Emoji routing ✔" setup=[GenieTestSetup] begin
    route("/✔") do
      "All good"
    end

    server, port = unique_server()

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/✔")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "All good"

    down()
    sleep(1)
    server = nothing
    port = nothing
  end;

  @testitem "Encoded urls é" setup=[GenieTestSetup] begin
    route("/réception") do
      "Meet at réception"
    end

    server, port = unique_server()

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/réception")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "Meet at réception"

    down()
    sleep(1)
    server = nothing
    port = nothing
  end;

  @testitem "Emoji routing with params" setup=[GenieTestSetup] begin
    using Genie, Genie.Requests
    route("/:check/:genie/:smallheart/:bigheart") do
      "/$(payload(:check))/$(payload(:genie))/$(payload(:smallheart))/$(payload(:bigheart))"
    end

    server, port = unique_server()

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port/✔/🧞/♥/❤")
    catch ex
      ex.response
    end

    @test response.status == 200
    @test String(response.body) == "/✔/🧞/♥/❤"

    down()
    sleep(1)
    server = nothing
    port = nothing
  end;

# end