"""
Caching functionality for Genie.
"""
module Cache
using DocStringExtensionsMock

import SHA, Logging
import Genie

export cachekey, withcache, @cache
export purge, purgeall


"""
$TYPEDSIGNATURES
"""
function init() :: Nothing
  @eval Genie.config.cache_storage === nothing && (Genie.config.cache_storage = :File)
  @eval Genie.config.cache_storage == :File && include(joinpath(@__DIR__, "cache_adapters", "FileCache.jl"))

  nothing
end


"""
$TYPEDSIGNATURES

Executes the function `f` and stores the result into the cache for the duration (in seconds) of `expiration`. Next time the function is invoked,
if the cache has not expired, the cached result is returned skipping the function execution.
The optional `dir` param is used to designate the folder where the cache will be stored (within the configured cache folder).
If `condition` is `false` caching will be skipped.
"""
function withcache end


"""
$TYPEDSIGNATURES

Removes the cache data stored under the `key` key.
"""
function purge end


"""
$TYPEDSIGNATURES

Removes all cached data.
"""
function purgeall end


macro cache(expr)
  quote
    withcache($(esc(string(expr)))) do
      $(esc(expr))
    end
  end
end


### PRIVATE ###


"""
$TYPEDSIGNATURES

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