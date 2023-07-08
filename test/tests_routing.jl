@safetestset "Routing edge cases" begin

  @safetestset "Emoji routing" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/✔/🧞/♥/❤") do _
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

  @safetestset "Emoji routing ✔" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/✔") do _
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

  @safetestset "Encoded urls é" begin
    using Genie
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/réception") do _
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

  @safetestset "Emoji routing with params" begin
    using Genie, Genie.Requests
    using HTTP

    port = nothing
    port = rand(8500:8900)

    route("/:check/:genie/:smallheart/:bigheart") do params
      "/$(params(:check))/$(params(:genie))/$(params(:smallheart))/$(params(:bigheart))"
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

end