module Jinnie

push!( LOAD_PATH, abspath("./") )
push!( LOAD_PATH, abspath("config") )
push!( LOAD_PATH, abspath("lib/") )
push!( LOAD_PATH, abspath("lib/Jinnie/src") )
push!( LOAD_PATH, abspath("app/controllers") )

include(abspath("config/routes.jl"))
include(abspath("lib/Jinnie/src/jinnie.jl"))

Jinnie.start_server()

end