"""
Easy to enable caching functionality for Genie - works with pluggable cache adapters for the persistance layer.
"""
module Cache

using Genie, SHA, Logger

export cache_key, with_cache, @cache_key


"""
Default period of time until the cache is expired.
"""
const CACHE_DURATION  = IS_IN_APP ? Genie.config.cache_duration : 600


"""
Underlying module that handles persistance and retrieval of cached data.
"""
const CACHE_ADAPTER_NAME = IS_IN_APP ? Genie.config.cache_adapter  : :FileCacheAdapter
eval(parse("using $(CACHE_ADAPTER_NAME)"))
const CACHE_ADAPTER = eval(parse("$CACHE_ADAPTER_NAME"))


"""
    with_cache(f::Function, key::Union{String,Symbol}, expiration::Int = CACHE_DURATION; dir = "", condition::Bool = true)

Executes the function `f` and stores the result into the cache for the duration (in seconds) of `expiration`. Next time the function is invoked,
if the cache has not expired, the cached result is returned skipping the function execution.
The optional `dir` param is used to designate the folder where the cache will be stored (within the configured cache folder).
If `condition` is `false` caching will be skipped.
"""
function with_cache(f::Function, key::Union{String,Symbol}, expiration::Int = CACHE_DURATION; dir = "", condition::Bool = true)
  ( expiration == 0 || ! condition ) && return f()

  cached_data = CACHE_ADAPTER.from_cache(cache_key(key), expiration, dir = dir)

  if isnull(cached_data)
    Genie.config.log_cache && Logger.log("Missed cache for $key", :warn)

    output = f()
    CACHE_ADAPTER.to_cache(cache_key(key), output, dir = dir)

    return output
  end

  Genie.config.log_cache && Logger.log("Hit cache for $(cache_key(key))", :info)

  Base.get(cached_data)
end


"""
    purge(key::Union{String,Symbol}) :: Void

Removes the cache data stored under the `key` key.
"""
function purge(key::Union{String,Symbol}; dir = "") :: Void
  CACHE_ADAPTER.purge(cache_key(key), dir = dir)
end


"""
    function purge_all() :: Void

Removes all cached data.
"""
function purge_all(; dir = "") :: Void
  CACHE_ADAPTER.purge_all(dir = dir)
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
    macro cache_key()

Generate a unique and repeatable cache key.
The key is generated using file path and line number, so editing code can invalidate the cache.
"""
macro cache_key()
  :(cache_key(esc(@__FILE__), esc(@__LINE__)))
end

end
