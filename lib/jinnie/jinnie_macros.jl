export @sayhello

macro sayhello()
	return quote
		println("hello")
	end
end

macro unless(test, branch)
    quote
        if ( ! $test )
          $branch
        end
    end
end