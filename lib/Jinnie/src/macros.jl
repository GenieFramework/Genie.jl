export @run_with_time, @unless

if config.app_env == "dev" 
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
  Jinnie.config.supress_output = true
  e = eval(expr)
  Jinnie.config.supress_output = false
  e
end

macro unless(test, branch)
  quote
    if ! $(esc(test))
      $(esc(branch))
    end
  end
end