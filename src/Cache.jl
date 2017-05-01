"""
Easy to enable caching functionality for Genie - works with pluggable cache adapters for the persistance layer.
"""
module Cache

using Genie, SHA, Logger

export cache_key, with_cache


"""
Default period of time until the cache is expired.
"""
const CACHE_DURATION  = IS_IN_APP ? Genie.config.cache_duration : 600


"""
Underlying module that handles persistance and retrieval of cached data.
"""
const CACHE_ADAPTER   = IS_IN_APP ? Genie.config.cache_adapter  : :FileCacheAdapter

eval(parse("using $(CACHE_ADAPTER)"))


"""
    with_cache(f::Function, key::String, expiration::Int = CACHE_DURATION; dir = "", condition::Bool = true)

Executes the function `f` and stores the result into the cache for the duration of `expiration`. Next time the function is invoked,
if the cache has not expired, the cached result is returned skipping the function execution.
The optional `dir` param is used to designate the folder where the cache will be stored (within the configured cache folder).
If `condition` is `false` caching will be skipped.
"""
function with_cache(f::Function, key::String, expiration::Int = CACHE_DURATION; dir = "", condition::Bool = true)
  ( expiration == 0 || ! condition ) && return f()

  ca = cache_adapter()
  cached_data = ca.from_cache(cache_key(key), expiration)
  if isnull(cached_data)
    Genie.config.log_cache && Logger.log("Missed cache for $key", :warn)

    output = f()
    ca.to_cache(cache_key(key), output, dir = dir)

    return output
  end

  Genie.config.log_cache && Logger.log("Hit cache for $key", :debug)
  Base.get(cached_data)
end


"""
    cache_key(args...) :: String

Computes a unique cache key based on `args`. Used to generate unique `key`s for storing data in cache.
"""
function cache_key(args...) :: String
  key = ""
  for a in args
    key *= string(a)
  end

  bytes2hex(sha1(key))
end


"""
    cache_adapter(adapter::Symbol = Genie.config.cache_adapter) :: Module

Returns the currently active cache adapter, as defined in the settings.
"""
function cache_adapter(adapter::Symbol = CACHE_ADAPTER) :: Module
  eval(parse("$adapter"))
end

end
