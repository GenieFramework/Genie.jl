# @testitem "Server functionality" setup=[GenieTestSetup] begin

  @testitem "Start/stop servers" setup=[GenieTestSetup] begin
    using Genie.Server

    Genie.Server.down!()
    empty!(Genie.Server.SERVERS)

    servers = Genie.Server.up()
    @test isopen(servers.webserver)

    servers = Genie.Server.down(servers)
    sleep(1)
    @test !isopen(servers.webserver)
    @test !isopen(Genie.Server.SERVERS[1].webserver)

    servers = Genie.Server.down!()
    empty!(Genie.Server.SERVERS)

    servers = Genie.Server.up(; open_browser = false)
    Genie.Server.down(servers; webserver = false)
    @test isopen(servers.webserver)

    servers = Genie.Server.down(servers; webserver = true)
    sleep(1)
    @test !isopen(servers.webserver)
    @test !isopen(Genie.Server.SERVERS[1].webserver)

    servers = nothing
  end;

  @testitem "Update config when custom startup args" setup=[GenieTestSetup] begin
    using Genie.Server

    port = Genie.config.server_port
    ws_port = Genie.config.websockets_port === nothing ? port : Genie.config.websockets_port

    server = Genie.Server.up(port+1_000; ws_port = ws_port+1_000, open_browser = false)

    @test Genie.config.server_port == port+1_000
    @test Genie.config.websockets_port == ws_port+1_000

    Genie.config.server_port = port
    Genie.config.websockets_port = ws_port

    Genie.Server.down()
    sleep(1)
    server = nothing
  end;

# end;