@safetestset "Server functionality" begin

  @safetestset "Start/stop servers" begin
    using Genie
    using Genie.Server

    Genie.Server.down()
    empty!(Genie.Server.SERVERS)

    servers = Genie.Server.up()
    @test servers.webserver.state == :runnable
    @test Genie.Server.SERVERS[1].webserver.state == :runnable

    servers = Genie.Server.down()
    sleep(1)
    @test servers[1].webserver.state == :done
    @test Genie.Server.SERVERS[1].webserver.state == :done

    servers = Genie.Server.up(; open_browser = false)
    Genie.Server.down(; webserver = false)
    sleep(1)
    @test servers.webserver.state == :runnable
    @test Genie.Server.SERVERS[2].webserver.state == :runnable

    servers = Genie.Server.down(; webserver = true)
    sleep(1)
    @test servers[1].webserver.state == :done
    @test servers[2].webserver.state == :done
    @test Genie.Server.SERVERS[1].webserver.state == :done
    @test Genie.Server.SERVERS[2].webserver.state == :done

    servers = nothing
  end;

  @safetestset "Update config when custom startup args" begin
    using Genie
    using Genie.Server

    port = Genie.config.server_port
    ws_port = Genie.config.websockets_port

    server = Genie.Server.up(port+1_000; ws_port = ws_port+1_000, open_browser = false)

    @test Genie.config.server_port == port+1_000
    @test Genie.config.websockets_port == ws_port+1_000

    Genie.config.server_port = port
    Genie.config.websockets_port = ws_port

    Genie.Server.down()
    sleep(1)
    server = nothing
  end;

end;