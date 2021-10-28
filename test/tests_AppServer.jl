@safetestset "AppServer functionality" begin

  @safetestset "Start/stop servers" begin
    using Genie
    using Genie.AppServer

    Genie.AppServer.down()
    empty!(Genie.AppServer.SERVERS)

    servers = Genie.AppServer.startup()
    @test servers.webserver.state == :runnable
    @test Genie.AppServer.SERVERS[1].webserver.state == :runnable

    servers = Genie.AppServer.down()
    sleep(1)
    @test servers[1].webserver.state == :done
    @test Genie.AppServer.SERVERS[1].webserver.state == :done

    servers = Genie.AppServer.startup(; open_browser = false)
    Genie.AppServer.down(; webserver = false)
    sleep(1)
    @test servers.webserver.state == :runnable
    @test Genie.AppServer.SERVERS[2].webserver.state == :runnable

    servers = Genie.AppServer.down(; webserver = true)
    sleep(1)
    @test servers[1].webserver.state == :done
    @test servers[2].webserver.state == :done
    @test Genie.AppServer.SERVERS[1].webserver.state == :done
    @test Genie.AppServer.SERVERS[2].webserver.state == :done

    servers = nothing
  end;

  @safetestset "Update config when custom startup args" begin
    using Genie
    using Genie.AppServer

    port = Genie.config.server_port
    ws_port = Genie.config.websockets_port

    server = Genie.AppServer.up(port+1_000; ws_port = ws_port+1_000, open_browser = false)

    @test Genie.config.server_port == port+1_000
    @test Genie.config.websockets_port == ws_port+1_000

    Genie.config.server_port = port
    Genie.config.websockets_port = ws_port

    Genie.AppServer.down()
    sleep(1)
    server = nothing
  end;

end;