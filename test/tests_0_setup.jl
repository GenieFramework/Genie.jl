@testmodule GenieTestSetup begin
    using Reexport
    @reexport using Genie
    @reexport using HTTP

    function __init__()
        Genie.config.server_port = 8000
        Genie.config.websockets_port = nothing
    end
end

@testitem "GenieTestSetup" setup=[GenieTestSetup] begin
    @test GenieTestSetup isa Module
end
