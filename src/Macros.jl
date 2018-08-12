"""
Various macro helpers.
"""
module Macros

using Genie, Genie.Configuration

export @devtools, @ifdevtools
export @run_with_time, @unless, @psst, @in_repl, @location_in_file

"""
    devtools()

Injects modules to be used in development mode, such as the `Gallium` debugger.
To be used as a concise one liner to include all the dev tools.

# Examples
```julia
julia> @devtools()
```
"""
macro devtools()
  if Configuration.is_dev()
    quote
      using Gallium
    end
  end
end


"""
    ifdevtools(expr::Expr)

Conditionally injects `expr::Expr` if the app runs in development mode.
The `Gallium` debugger is automatically also included.

# Examples
```julia
julia> @ifdevtools :(println("dev mode")) |> Core.eval
dev mode
```
"""
macro ifdevtools(expr::Expr)
  if Configuration.is_dev()
    quote
      using Gallium
      $(esc(expr))
    end
  end
end


"""
    runwithtime(expr::Expr)

Prepends `@time` to `expr` if the app runs in development mode and evals - otherwise it simply evals `expr`.
To be used to automatically disable timed execution outside `dev` mode.

# Examples
```julia
julia> @run_with_time rand(2,2)
  0.059437 seconds (39.18 k allocations: 1.586 MB)
2×2 Array{Float64,2}:
 0.294566  0.653612
 0.264837  0.337146
```
"""
macro runwithtime(expr::Expr)
  if Configuration.is_dev()
    quote
      @time $(esc(expr))
    end
  else
    expr
  end
end


"""
    macro location_in_file()

Returns the location (file name and line number) in the file where it's called.
"""
macro location_in_file()
  :(String(esc(@__FILE__) * ":" * esc(@__LINE__)))
end

end
