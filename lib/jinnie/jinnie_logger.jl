module Jinnie_Logger

function req(req)
	println("jinnie_middlewares.jl")
	println( Dates.now() )
	@show req[:query]
	@show req[:method]
	@show req[:path]
	@show req[:data]
end

end