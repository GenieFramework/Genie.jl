module Repl

import REPL, REPL.Terminals

"""
    replprint(output::String, terminal;
                    newline::Int = 0, clearline::Int = 1, color::Symbol = :white, bold::Bool = false, sleep_time::Float64 = 0.2,
                    prefix::String = "", prefix_color::Symbol = :green, prefix_bold::Bool = true)

Prints app customise messages to the console.
"""
function replprint(output::String, terminal;
                    newline::Int = 0, clearline::Int = newline + 1,
                    color::Symbol = :white, bold::Bool = false, sleep_time::Float64 = 0.2,
                    prefix::String = "", prefix_color::Symbol = :green, prefix_bold::Bool = true)

  for i in newline:(clearline + newline)
    REPL.Terminals.clear_line(terminal)
  end

  isempty(prefix) || printstyled(prefix, color = prefix_color, bold = prefix_bold)
  printstyled(output, color = color, bold = bold)


  for i in 1:newline
    println()
  end

  sleep(sleep_time)
end

end