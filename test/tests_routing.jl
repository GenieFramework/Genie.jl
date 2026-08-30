# @testitem "Routing edge cases" begin

  @testitem "Emoji routing" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/✔/🧞/♥/❤") do
      "/✔/🧞/♥/❤"
    end

    server = up(port)

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

  @testitem "Emoji routing ✔" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/✔") do
      "All good"
    end

    server = up(port)

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

  @testitem "Encoded urls é" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/réception") do
      "Meet at réception"
    end

    server = up(port)

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

  @testitem "Emoji routing with params" begin
    using Genie, Genie.Requests
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/:check/:genie/:smallheart/:bigheart") do
      "/$(payload(:check))/$(payload(:genie))/$(payload(:smallheart))/$(payload(:bigheart))"
    end

    server = up(port)

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