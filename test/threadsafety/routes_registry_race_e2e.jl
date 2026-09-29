using Test
using Genie, Genie.Router, Genie.Renderer.Json
using HTTP

"""
End-to-end reproduction/verification for the `_routes` registry race
(src/Router.jl:119, `_routes::OrderedCollections.LittleDict{Symbol,Route}`).

Unlike ROUTE_CACHE, this one is triggered by DYNAMIC route registration —
`route(...)` called while the server is already serving `:threads`-mode
traffic (lazy/per-tenant routes, plugins registering on first use, hot
reload). `Router.push!` (the writer) already took `_routes_lock`/
`_channels_lock` before this fix; what was missing was the READER side —
`routes()`, `channels()`, `isroute()`, `get_route()`, `ischannel()` all read
`_routes`/`_channels` without the lock, so a concurrent reader could still
observe a writer's `LittleDict` mid-mutation.

This test continuously registers new routes from one task while a flood of
concurrent requests exercises `match_routes` (walking the full `_routes`
registry) from many other threads, under `server_handler_mode = :threads`.

    julia --project --threads=8 test/threadsafety/routes_registry_race_e2e.jl
"""

const PORT = 8791
const NBASE_ROUTES = 50
const NDYNAMIC_ROUTES = 300
const NCONCURRENT_REQUESTS_PER_WAVE = 50

Genie.config.run_as_server = true
Genie.config.server_handler_mode = :threads
Genie.config.app_env = Genie.Configuration.PROD

for i in 1:NBASE_ROUTES
    route("/base/route$(i)/:id") do
        json(Dict(:ok => true, :route => i))
    end
end

up(PORT; async = true)
sleep(1)

failures = Any[]

# Task 1: keeps registering brand-new routes throughout the test, exactly
# the "route(...) called after the server is already live" scenario.
registrar = Threads.@spawn begin
    for i in 1:NDYNAMIC_ROUTES
        route("/dynamic/route$(i)/:id") do
            json(Dict(:ok => true, :route => i))
        end
        # no sleep: register as fast as possible to maximize overlap with
        # concurrent readers below
    end
end

# Task 2..N: concurrent request waves hitting the (growing) route table
# while registration is still in flight.
reader_errors = Any[]
reader_lock = ReentrantLock()

for wave in 1:20
    base_targets = ["http://127.0.0.1:$PORT/base/route$(rand(1:NBASE_ROUTES))/42" for _ in 1:NCONCURRENT_REQUESTS_PER_WAVE]

    @sync for url in base_targets
        Threads.@spawn begin
            try
                resp = HTTP.get(url; retry = false)
                resp.status == 200 || lock(reader_lock) do
                    push!(reader_errors, (wave = wave, url = url, status = resp.status))
                end
            catch e
                lock(reader_lock) do
                    push!(reader_errors, (wave = wave, url = url, error = e))
                end
            end
        end
    end
end

wait(registrar)

down()

@testset "_routes registry race under concurrent registration + :threads mode" begin
    @test isempty(reader_errors)
    @test length(Genie.Router.routes()) == NBASE_ROUTES + NDYNAMIC_ROUTES
    isempty(reader_errors) || @error "reproduced _routes registry race" reader_errors
end
