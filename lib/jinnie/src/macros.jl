export @unless
export @run_with_time

macro unless(test, branch)
    quote
        if ( ! $test )
          $branch
        end
    end
end

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