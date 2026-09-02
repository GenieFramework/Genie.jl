@testmodule GenieTestSetup begin
    using Genie
    using Reexport
    @reexport using Genie
    @reexport using HTTP
    using Sockets
    using Test

    port::Int = haskey(ENV, "WORKER_PORT") ? parse(Int, ENV["WORKER_PORT"]) : Genie.config.server_port
    ws_port::Int = haskey(ENV, "WORKER_WS_PORT") ? parse(Int, ENV["WORKER_WS_PORT"]) : Genie.config.websockets_port === nothing ? 0 : Genie.config.websockets_port

    const PORTS = Set{Int}()

    export unique_test_port, start_unique_server, port, ws_port

    # provides and blocks a free port for 1s for a test server to bind to
    function unique_test_port()
        local freeport
        server = Sockets.listen(ip"127.0.0.1", 0)
        try
            sockname = Sockets.getsockname(server)
            freeport = sockname isa Tuple ? Int(last(sockname)) : Int(sockname.port)
            push!(GenieTestSetup.PORTS, freeport)
            Timer(1.0) do 
                setdiff!(GenieTestSetup.PORTS, [freeport])
            end
            freeport
        catch
            @warn("Failed to get a free port, falling back to random port in 8000-9000 range.")
            rand(8000:9000)
        finally
            close(server)
        end
    end

    function start_unique_server(; single_port = true, async = true)
        global port, ws_port
        ws_port = single_port ? 0 : unique_test_port()
        Genie.Server.down!()
        server = up(; port = 0, ws_port, async)
        ENV["WORKER_PORT"] = port = server.webserver.bound_port
        ws_port = if server.websockets === nothing
            port
        else
            server.websockets.listener === nothing ? 0 : Int(server.websockets.listener.fd.laddr.port)
        end
        return server
    end

    if !Genie.Server.isrunning(:webserver) || ws_port != 0
        Genie.Server.down!
        start_unique_server()
    else
        Genie.Server.server_status(Genie.Server.SERVERS[end], :webserver)
    end
end

@testitem "GenieTestSetup" setup=[GenieTestSetup] begin
    @test GenieTestSetup isa Module
end
