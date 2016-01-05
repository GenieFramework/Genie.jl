module Jinnie

push!( LOAD_PATH, abspath("./") )
push!( LOAD_PATH, abspath("config") )
push!( LOAD_PATH, abspath("lib/jinnie") )
push!( LOAD_PATH, abspath("app/controllers") )

include(abspath("config/routes.jl"))
include(abspath("lib/jinnie/jinnie.jl"))

Jinnie.start_server()

end