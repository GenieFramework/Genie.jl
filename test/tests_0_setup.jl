@testmodule GenieTestSetup begin
    using Reexport
    @reexport using Genie
    @reexport using HTTP
    using Sockets
    using Test

    export unique_test_port

    function unique_test_port()
        server = Sockets.listen(ip"127.0.0.1", 0)
        try
            sockname = Sockets.getsockname(server)
            return sockname isa Tuple ? Int(last(sockname)) : Int(sockname.port)
        finally
            close(server)
        end
    end

    function __init__()
        @test Genie.config.websockets_port === nothing
        @test Genie.config.websockets_port === nothing
    end
end

@testitem "GenieTestSetup" setup=[GenieTestSetup] begin
    @test GenieTestSetup isa Module
end
