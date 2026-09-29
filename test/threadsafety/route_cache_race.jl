using Test
using Genie

"""
Reproduces the ROUTE_CACHE data race that `Router.match_routes` hits on every
request in production mode:

    get!(ROUTE_CACHE, r.path, parse_route(r.path, context = r.context))

`ROUTE_CACHE` is a plain `Dict` — Julia's `Dict` is not safe for concurrent
mutation from multiple OS threads. A cache miss triggers an internal
insert/rehash; two threads racing that at once can corrupt the table
(BoundsError, wrong lookups, or a crash).

The race is probabilistic and depends on real concurrent contention on the
underlying hash table, which is why casually clicking through an app under
`server_handler_mode = :threads` usually does NOT reproduce it: routes get
cached one at a time in practice. To force the collision reliably we mimic
the one realistic trigger that does hit it — many never-before-seen routes
requested at the same instant (e.g. a frontend firing several concurrent
`fetch()` calls on first page load) — and repeat many times since a single
attempt can get lucky.

Run this test BEFORE and AFTER a proposed fix (e.g. wrapping ROUTE_CACHE
access in a lock) to prove the fix actually closes the race:

    julia --project --threads=8 test/threadsafety/route_cache_race.jl
"""

# Call this exact code path — the one Router.match_routes uses — through a
# pluggable accessor so the same test can validate a locked replacement.
unsafe_cache_lookup(path) =
    get!(Genie.Router.ROUTE_CACHE, path, Genie.Router.parse_route(path))

function stress_route_cache(lookup::Function; nthreads = Threads.nthreads(), nfresh_routes = 200, repeats = 200)
    @assert nthreads > 1 "needs julia --threads=N with N>1 to exhibit the race"

    for rep in 1:repeats
        empty!(Genie.Router.ROUTE_CACHE)

        # A batch of routes nobody has requested yet, each one to be hit by
        # EVERY thread at (as close as possible to) the same instant —
        # models N concurrent first-time requests to N fresh endpoints.
        fresh_paths = ["/stress/rep$(rep)/route/:id$(i)" for i in 1:nfresh_routes]

        results  = Vector{Any}(undef, nthreads)
        raised   = Vector{Any}(undef, nthreads)
        fill!(raised, nothing)

        @sync for t in 1:nthreads
            Threads.@spawn begin
                try
                    results[t] = [lookup(p) for p in fresh_paths]
                catch e
                    raised[t] = e
                end
            end
        end

        errs = filter(!isnothing, raised)
        if !isempty(errs)
            return (failed = true, rep = rep, errors = errs)
        end

        # Even with no exception, corruption can silently produce the wrong
        # parsed tuple for a path, or a cache that's missing entries it
        # should have. Cross-check every thread agrees on every route.
        for p_idx in eachindex(fresh_paths)
            seen = Set(r[p_idx] for r in results)
            if length(seen) != 1
                return (failed = true, rep = rep, mismatch = fresh_paths[p_idx], seen = seen)
            end
        end
        if length(Genie.Router.ROUTE_CACHE) != nfresh_routes
            return (failed = true, rep = rep, bad_length = length(Genie.Router.ROUTE_CACHE), expected = nfresh_routes)
        end
    end

    return (failed = false,)
end

@testset "ROUTE_CACHE concurrent access under :threads handler mode" begin
    result = stress_route_cache(unsafe_cache_lookup)
    @test !result.failed
    result.failed && @error "route cache race reproduced" result
end
