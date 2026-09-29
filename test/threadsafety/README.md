# Thread-safety regression scripts

These are deliberately **not** `@testitem`s and are **not** run by `Pkg.test()`.

They reproduce concurrency races under `server_handler_mode`/`server_ws_handler_mode
= :threads` (unlocked shared state racing across genuinely parallel OS threads) and
verify the fixes for them. Some of them are designed to probe for hangs, not just
exceptions — a regression here can mean the process never returns, not just a failed
assertion. `TestItemRunner` runs every `@testitem` via `Core.eval` into a fresh module
in the *same* process, with no isolation and no per-item timeout, and VS Code's Testing
panel can discover and run `@testitem`s directly, bypassing any filter in
`runtests.jl`. Making these `@testitem`s — even tagged and filtered out of the default
run — would mean a single accidental "Run All Tests" click, from either `Pkg.test()`
or the IDE panel, could hang the whole test run indefinitely.

Keeping them as plain scripts means no `@testitem`-aware tool can discover or run them
by accident. Run each one explicitly, in its own process, with the thread count that
matters for what it's testing:

```
julia --project --threads=8 test/threadsafety/route_cache_race.jl
julia --project --threads=8 test/threadsafety/route_cache_race_e2e.jl
julia --project --threads=8 test/threadsafety/routes_registry_race_e2e.jl
julia --project --threads=8 test/threadsafety/webchannels_race_e2e.jl
```

If one hangs, that's itself a finding — kill the process and investigate, rather than
waiting.
