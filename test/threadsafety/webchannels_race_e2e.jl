using Test
using Genie, Genie.Router, Genie.Assets
using HTTP

"""
End-to-end reproduction/verification for the WebChannels race
(src/WebChannels.jl: CLIENTS, SUBSCRIPTIONS, MESSAGE_QUEUE — previously plain,
unlocked `Dict`s, now guarded by `WEBCHANNELS_LOCK`).

Mirrors how a real Stipple app is exposed: `channels_subscribe` registers the
same `/channel/subscribe` and `/channel/unsubscribe` WS channels a Stipple
page's JS client uses. Many concurrent WebSocket connections subscribe and
unsubscribe from the SAME channel at once, under `server_ws_handler_mode =
:threads` — exactly the condition under which CPU-heavy `@handler`/`@onbutton`
code (the reason `:threads` mode exists at all) runs on `:default`-pool
threads and pushes reactive updates back out through this module.

    julia --project --threads=8 test/threadsafety/webchannels_race_e2e.jl
"""

const PORT = 8792
const NCLIENTS = 60
const NCYCLES = 5

Genie.config.run_as_server = true
Genie.config.websockets_server = true
Genie.config.server_ws_handler_mode = :threads
Genie.config.app_env = Genie.Configuration.PROD

Genie.Assets.channels_subscribe("stress")

up(PORT; async = true)
sleep(1)

failures = Any[]
failures_lock = ReentrantLock()

# NOTE: channels_subscribe's unsubscribe handler calls Router.delete_channel!,
# which removes the "/stress/unsubscribe" route entirely after first use —
# fine for one channel per session, but not for many clients sharing one
# channel name. So instead of explicitly unsubscribing, each simulated client
# subscribes and then just disconnects — exactly how a real browser tab going
# away behaves — which exercises `subscribe()` (concurrent inserts) and the
# disconnect-triggered `unsubscribe_client()` cleanup path (concurrent
# deletes) without hitting that unrelated route-deletion behavior.
@sync for i in 1:NCLIENTS
    Threads.@spawn begin
        for cyc in 1:NCYCLES
            try
                HTTP.WebSockets.open("ws://127.0.0.1:$PORT/") do ws
                    HTTP.WebSockets.send(ws, """{"channel":"stress","message":"subscribe"}""")
                    resp = HTTP.WebSockets.receive(ws)
                    resp == "Subscription: OK" || lock(failures_lock) do
                        push!(failures, (client = i, cycle = cyc, step = :subscribe, got = resp))
                    end
                    # connection closes here as the `do` block exits, triggering
                    # server-side unsubscribe_client() cleanup concurrently with
                    # every other client doing the same thing at once
                end
            catch e
                lock(failures_lock) do
                    push!(failures, (client = i, cycle = cyc, error = e))
                end
            end
        end
    end
end

down()

@testset "WebChannels CLIENTS/SUBSCRIPTIONS race under concurrent subscribe/unsubscribe + :threads ws mode" begin
    @test isempty(failures)
    isempty(failures) || @error "reproduced WebChannels race" failures
end
