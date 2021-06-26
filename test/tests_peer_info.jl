@safetestset "Peer info" begin
  @safetestset "Peer info is disabled by default" begin
    using Genie, Genie.Requests
    using HTTP

    port = rand(8500:8900)

    route("/") do
      "$(peer().ip)-$(peer().port)"
    end

    server = up(port)

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port")
    catch ex
      ex.response
    end

    @test Genie.config.features_peerinfo == false
    @test response.status == 200
    @test String(response.body) == "-"

    down()
    sleep(1)
    server = nothing
  end;

  @safetestset "Peer info can be activated" begin
    using Genie, Genie.Requests
    using HTTP

    port = rand(8500:8900)
    Genie.config.features_peerinfo = true

    route("/") do
      "$(peer().ip)-$(peer().port)"
    end

    server = up(port)

    response = try
      HTTP.request("GET", "http://127.0.0.1:$port")
    catch ex
      ex.response
    end

    @show String(response.body)

    @test Genie.config.features_peerinfo == true
    @test response.status == 200
    @test_broken String(response.body) == "127.0.0.1-$port"

    down()
    sleep(1)
    server = nothing
  end;

end