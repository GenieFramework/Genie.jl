dev = false

macro do_it(expr)
	if dev
		@time expr
	else
		expr
	end
end

@do_it println("foo")