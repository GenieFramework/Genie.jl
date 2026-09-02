# @testitem "Peer info" setup=[GenieTestSetup] begin
  @testitem "Peer info is disabled by default but can be activated" setup=[GenieTestSetup] begin
    using Genie, Genie.Requests
    route("/") do
      "$(peer().ip)-$(peer().port)"
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$PORT")
    catch ex
      ex.response
    end

    @test Genie.config.features_peerinfo == false
    @test response.status == 200
    @test String(response.body) == "-"

    Genie.Server.down!()
    sleep(0)
    start_unique_server()

    Genie.config.features_peerinfo = true

    route("/") do
      "$(peer().ip)-$(peer().port)"
    end

    response = try
      HTTP.request("GET", "http://127.0.0.1:$PORT")
    catch ex
      ex.response
    end

    @test Genie.config.features_peerinfo == true
    @test response.status == 200
    @test_broken String(response.body) == "127.0.0.1-$PORT"
    Genie.config.features_peerinfo = false
  end;

# end