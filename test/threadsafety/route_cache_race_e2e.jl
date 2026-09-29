using Test
using Genie, Genie.Router, Genie.Renderer.Json
using HTTP

"""
End-to-end reproduction of the ROUTE_CACHE race through a real running Genie
server with `server_handler_mode = :threads`, using an entirely static route
table — exactly how a normal app is structured (all routes registered once,
before `up()`, never touched again).

`ROUTE_CACHE` (src/Router.jl:49) is keyed by the REGISTERED route pattern,
not the incoming request URL, and `match_routes` walks every same-method
route in order, populating the cache for each one it checks until it finds a
match. So a single request can trigger `get!` for many route entries at
once, and the only precondition for the race is that the cache is still cold
— which is simply true right after every (re)start, before traffic has
warmed it. No dynamic route registration, unusual routing, or app-level
concurrency is required.

The only artificial element below is `empty!(ROUTE_CACHE)` between bursts —
a stand-in for "server just (re)started" so we can repeat the cold-cache
condition many times in one process run instead of literally restarting
Julia 50 times. A single burst right after the one real `up()` call is
already a faithful, complete reproduction of what a production restart plus
concurrent traffic looks like; the repeat loop only exists to beat the
race's probabilistic nature within a single test run.

Run in its own process (corruption can, in the worst case, hang rather than
throw a catchable exception — see route_cache_race.jl):

    julia --project --threads=8 test/threadsafety/route_cache_race_e2e.jl
"""

const PORT = 8790
const NROUTES = 300   # static route table, defined once — like any real app
const NBURSTS = 50    # repetitions of the cold-cache condition, to beat the race's odds

Genie.config.run_as_server = true
Genie.config.server_handler_mode = :threads   # the mode under test
Genie.config.app_env = Genie.Configuration.PROD  # ROUTE_CACHE is only used in prod

# Routes are registered ONCE, up front, before the server ever starts —
# never modified again for the lifetime of the test.
for i in 1:NROUTES
    route("/stress/route$(i)/:id") do
        json(Dict(:ok => true, :route => i))
    end
end

up(PORT; async = true)
sleep(1)  # let the listener bind

const URLS = ["http://127.0.0.1:$PORT/stress/route$(i)/42" for i in 1:NROUTES]

failures = Any[]

for burst in 1:NBURSTS
    empty!(Genie.Router.ROUTE_CACHE)  # simulates "just (re)started" — routes themselves never change

    statuses = Vector{Int}(undef, length(URLS))
    errs = Vector{Any}(undef, length(URLS))
    fill!(errs, nothing)

    # Every route hit at once, concurrently — modelling e.g. k8s liveness +
    # readiness probes and/or real users arriving right after a restart,
    # before the cache has had a chance to warm up sequentially.
    @sync for (idx, url) in enumerate(URLS)
        Threads.@spawn begin
            try
                resp = HTTP.get(url; retry = false)
                statuses[idx] = resp.status
            catch e
                errs[idx] = e
            end
        end
    end

    bad     = [(URLS[i], errs[i]) for i in eachindex(URLS) if errs[i] !== nothing]
    non200  = [(URLS[i], statuses[i]) for i in eachindex(URLS) if errs[i] === nothing && statuses[i] != 200]

    if !isempty(bad) || !isempty(non200)
        push!(failures, (burst = burst, request_errors = bad, bad_statuses = non200))
    end
end

down()

@testset "ROUTE_CACHE race on a static route table under :threads mode" begin
    @test isempty(failures)
    isempty(failures) || @error "reproduced via real HTTP path (static routes)" failures
end
