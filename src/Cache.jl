"""
Easy to enable caching functionality for Genie - works with pluggable cache adapters for the persistance layer.
"""
module Cache

using Genie, SHA, Genie.Loggers, Nullables

export cachekey, withcache, @cachekey


"""
Default period of time until the cache is expired.
"""
const CACHE_DURATION  = Genie.config.cache_duration


"""
Underlying module that handles persistance and retrieval of cached data.
"""
const CACHE_ADAPTER_NAME = Genie.config.cache_adapter
Core.eval(@__MODULE__, Meta.parse("""include("cache_adapters/$CACHE_ADAPTER_NAME.jl")"""))
Core.eval(@__MODULE__, Meta.parse("using .$(CACHE_ADAPTER_NAME)"))
const CACHE_ADAPTER = Core.eval(@__MODULE__, Meta.parse("$CACHE_ADAPTER_NAME"))


"""
    with_cache(f::Function, key::Union{String,Symbol}, expiration::Int = CACHE_DURATION; dir = "", condition::Bool = true)

Executes the function `f` and stores the result into the cache for the duration (in seconds) of `expiration`. Next time the function is invoked,
if the cache has not expired, the cached result is returned skipping the function execution.
The optional `dir` param is used to designate the folder where the cache will be stored (within the configured cache folder).
If `condition` is `false` caching will be skipped.
"""
function withcache(f::Function, key::Union{String,Symbol}, expiration::Int = CACHE_DURATION; dir::String = "", condition::Bool = true)
  ( expiration == 0 || ! condition ) && return f()

  cached_data = CACHE_ADAPTER.fromcache(cachekey(key), expiration, dir = dir)

  if isnull(cached_data)
    Genie.config.log_cache && log("Missed cache for $key", :warn)

    output = f()
    CACHE_ADAPTER.tocache(cachekey(key), output, dir = dir)

    return output
  end

  Genie.config.log_cache && log("Hit cache for $(cachekey(key))", :info)

  Base.get(cached_data)
end
const with_cache = withcache


"""
    purge(key::Union{String,Symbol}) :: Nothing

Removes the cache data stored under the `key` key.
"""
function purge(key::Union{String,Symbol}; dir::String = "") :: Nothing
  CACHE_ADAPTER.purge(cachekey(key), dir = dir)
end


"""
    function purgeall() :: Nothing

Removes all cached data.
"""
function purgeall(; dir = "") :: Nothing
  CACHE_ADAPTER.purgeall(dir = dir)
end
const purge_all = purgeall


"""
    cachekey(args...) :: String

Computes a unique cache key based on `args`. Used to generate unique `key`s for storing data in cache.
"""
function cachekey(args...) :: String
  key = IOBuffer()
  for a in args
    print(key, string(a))
  end

  bytes2hex(sha1(String(take!(key))))
end


"""
    macro cachekey()

Generate a unique and repeatable cache key.
The key is generated using file path and line number, so editing code can invalidate the cache.
"""
macro cachekey()
  :(cachekey(esc(@__FILE__), esc(@__LINE__)))
end

end
