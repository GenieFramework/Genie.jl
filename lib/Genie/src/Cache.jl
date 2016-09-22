module Cache
using Genie, SHA, Logger
eval(parse("using $(Genie.config.cache_adapter)"))

export cache_key, with_cache

function with_cache(f::Function, key::String, expiration::Int = Genie.config.cache_duration)
  expiration == 0 && return f()

  ca = cache_adapter()
  cached_data = ca.from_cache(key, expiration)
  if isnull(cached_data)
    Genie.config.log_cache && Logger.log("Missed cache for $key", :warn)

    output = f()
    ca.to_cache(key, output)

    return output
  end

  Genie.config.log_cache && Logger.log("Hit cache for $key", :debug)
  Base.get(cached_data)
end

function cache_key(args...)
  key = ""
  for a in args
    key *= string(a)
  end

  bytes2hex(sha1(key))
end

function cache_adapter(adapter::Symbol = Genie.config.cache_adapter)
  eval(adapter)
end

end