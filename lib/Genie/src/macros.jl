export @run_with_time, @unless

if Genie.config.app_env == "dev" 
  macro run_with_time(expr)
    quote
        @time $(esc(expr))
    end
  end
else 
  macro run_with_time(expr)
    expr
  end
end

macro psst(expr)
  Genie.config.supress_output = true
  evx = eval(expr)
  Genie.config.supress_output = false
  evx
end

macro unless(test, branch)
  quote
    if ! $(esc(test))
      $(esc(branch))
    end
  end
end