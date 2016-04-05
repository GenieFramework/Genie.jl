module Server

using Mux
using Jinnie

include(abspath("lib/Jinnie/src/controller.jl"))
include(abspath("lib/Jinnie/src/mux_extensions.jl"))

function start_server(server_port = 8000; reload = false)
  @app app =
      (
        Mux.defaults,
        Mux.stack(Jinnie.req_logger),
        eval(routes)...,
        Mux.notfound()
      )

  if reload return end

  serve(app, server_port)
end

end