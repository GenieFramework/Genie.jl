@safetestset "App Config" begin
  @safetestset "Custom server startup overwrites app config" begin
    using Genie

    @test Genie.config.server_port  == 8000
    @test Genie.config.server_host  == "127.0.0.1"
    @test Genie.config.websockets_port == 8000
    @test Genie.config.run_as_server   == false

    up(9000, "0.0.0.0"; open_browser = false)

    @test Genie.config.server_port  == 9000
    @test Genie.config.server_host  == "0.0.0.0"
    @test Genie.config.websockets_port == 9000
    @test Genie.config.run_as_server   == false

    down()

    up(9000, "0.0.0.0", ws_port = 9999; open_browser = false)

    @test Genie.config.server_port  == 9000
    @test Genie.config.server_host  == "0.0.0.0"
    @test Genie.config.websockets_port == 9999
    @test Genie.config.run_as_server   == false

    down()

    Genie.config.server_port  = 8000
    Genie.config.server_host  = "127.0.0.1"
    Genie.config.websockets_port = 8000
    Genie.config.run_as_server   = false

    down()
  end;
end;
