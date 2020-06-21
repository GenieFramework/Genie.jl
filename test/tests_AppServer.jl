@safetestset "AppServer functionality" begin

  @safetestset "Start/stop servers" begin
    using Genie
    using Genie.AppServer

    servers = Genie.AppServer.startup()
    @test servers.webserver.state == :runnable
    @test Genie.AppServer.SERVERS.webserver.state == :runnable

    servers = Genie.AppServer.down()
    sleep(1)
    @test servers.webserver.state == :done
    @test Genie.AppServer.SERVERS.webserver.state == :done

    servers = Genie.AppServer.startup()
    Genie.AppServer.down(; webserver = false)
    sleep(1)
    @test servers.webserver.state == :runnable
    @test Genie.AppServer.SERVERS.webserver.state == :runnable

    servers = Genie.AppServer.down(; webserver = true)
    sleep(1)
    @test servers.webserver.state == :done
    @test Genie.AppServer.SERVERS.webserver.state == :done
  end;

  @safetestset "Update config when custom startup args" begin
    using Genie
    using Genie.AppServer

    port = Genie.config.server_port
    ws_port = Genie.config.websockets_port

    Genie.AppServer.up(port+1_000; ws_port = ws_port+1_000)

    @test Genie.config.server_port == port+1_000
    @test Genie.config.websockets_port == ws_port+1_000

    Genie.config.server_port = port
    Genie.config.websockets_port = ws_port

    Genie.AppServer.down()
  end;

end;