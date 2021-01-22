"""
Caching functionality for Genie.
"""
module Cache

import SHA, Logging
import Genie

export cachekey, withcache, @cachekey
export purge, purgeall


function init() :: Nothing
  @eval isnothing(Genie.config.cache_storage) && (Genie.config.cache_storage = :File)
  @eval Genie.config.cache_storage == :File && include(joinpath(@__DIR__, "cache_adapters", "FileCache.jl"))

  nothing
end


"""
    withcache(f::Function, key::Union{String,Symbol}, expiration::Int = Genie.config.cache_duration; dir = "", condition::Bool = true)

Executes the function `f` and stores the result into the cache for the duration (in seconds) of `expiration`. Next time the function is invoked,
if the cache has not expired, the cached result is returned skipping the function execution.
The optional `dir` param is used to designate the folder where the cache will be stored (within the configured cache folder).
If `condition` is `false` caching will be skipped.
"""
function withcache end


"""
    purge()

Removes the cache data stored under the `key` key.
"""
function purge end


"""
    purgeall()

Removes all cached data.
"""
function purgeall end


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