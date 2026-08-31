@testmodule GenieTestSetup begin
    const PORTS = Set{Int}()

    using Reexport
    @reexport using Genie
    @reexport using HTTP
    using Sockets
    using Test

    export unique_test_port, unique_server

    function unique_test_port()
        server = Sockets.listen(ip"127.0.0.1", 0)
        try
            sockname = Sockets.getsockname(server)
            port = sockname isa Tuple ? Int(last(sockname)) : Int(sockname.port)
            push!(GenieTestSetup.PORTS, port)
            Timer(1.0) do 
                setdiff!(GenieTestSetup.PORTS, [port])
            end
            port
        catch
            rand(8000:9000)
        finally
            close(server)
        end
    end

    function unique_server()
        port = unique_test_port()
        server = up(port)
        return server, port
    end

    function __init__()
        @test Genie.config.websockets_port === nothing
        @test Genie.config.websockets_port === nothing
    end
end

@testitem "GenieTestSetup" setup=[GenieTestSetup] begin
    @test GenieTestSetup isa Module
end
