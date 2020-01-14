"""
Caching functionality for Genie.
"""
module Cache

import Revise
import SHA, Logging
import Genie

export cachekey, withcache, @cachekey
export purge, purgeall


function cache_adapter(m::Module)
  @eval const CACHE_ADAPTER = m
end


"""
    withcache(f::Function, key::Union{String,Symbol}, expiration::Int = Genie.config.cache_duration; dir = "", condition::Bool = true)

Executes the function `f` and stores the result into the cache for the duration (in seconds) of `expiration`. Next time the function is invoked,
if the cache has not expired, the cached result is returned skipping the function execution.
The optional `dir` param is used to designate the folder where the cache will be stored (within the configured cache folder).
If `condition` is `false` caching will be skipped.
"""
function withcache(f::Function, key::Union{String,Symbol}, expiration::Int = Genie.config.cache_duration; dir::String = "", condition::Bool = true)
  ( expiration == 0 || ! condition ) && return f()

  cached_data = CACHE_ADAPTER.fromcache(cachekey(key), expiration, dir = dir)

  if cached_data === nothing
    Genie.config.log_cache && @warn("Missed cache for $key")

    output = f()
    CACHE_ADAPTER.tocache(cachekey(key), output, dir = dir)

    return output
  end

  Genie.config.log_cache && @info("Hit cache for $(cachekey(key))")

  cached_data
end


"""
    purge(key::Union{String,Symbol}; dir::String = "") :: Nothing

Removes the cache data stored under the `key` key.
"""
function purge(key::Union{String,Symbol}; dir::String = "") :: Nothing
  CACHE_ADAPTER.purge(cachekey(key), dir = dir)
end


"""
    purgeall(; dir::String = "") :: Nothing

Removes all cached data.
"""
function purgeall(; dir::String = "") :: Nothing
  CACHE_ADAPTER.purgeall(dir = dir)
end


### PRIVATE ###


"""
    cachekey(args...) :: String

Computes a unique cache key based on `args`. Used to generate unique `key`s for storing data in cache.
"""
function cachekey(args...) :: String
  key = IOBuffer()
  for a in args
    print(key, string(a))
  end

  bytes2hex(SHA.sha1(String(take!(key))))
end

end