using Debug
using FactCheck

macro _doctest(expr)
  quote
      $(esc(expr)) |> eval
  end
end

@debug function doctest(expr)
  cursor = "julia> "
  lines = split(expr, "\n")
  
  if ! startswith(lines[1], cursor) 
    error("Invalid input. Quoted REPL code should begin with \"$cursor\"")
  end

  input = []
  output = []
  for l in lines 
    if startswith(l, cursor) 
      push!(input, replace(lines[1], r"^julia> ", ""))
    elseif startswith(l, repeat(" ", length(cursor)))
      push!(input, l)
    else 
      push!(output, l)
    end
  end

  input = join(input, "\n")
  output = replace(join(output, "\n"), """""", "")

  result = eval(parse(input))
  
  @fact result --> output
end

s = """
julia> join(1:10, "-")
"1-2-3-4-5-6-7-8-9-10"
"""

doctest(s)