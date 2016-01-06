module Jinnie_Logger

function req(req)
  println("")
	println( Dates.now() )
	@show req[:query]
	@show req[:method]
	@show req[:path]
  @show typeof(req[:path])
  @show length(req[:path])
	@show req[:data]
end

end