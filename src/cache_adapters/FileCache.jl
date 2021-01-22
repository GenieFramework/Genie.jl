module FileCache

import Serialization
import Genie, Genie.Cache

const SESSIONS_FOLDER = "sessions"

#===#
# IMPLEMENTATION #

"""
    tocache(key::Union{String,Symbol}, content::Any; dir::String = "") :: Nothing

Persists `content` onto the file system under the `key` key.
"""
function tocache(key::Union{String,Symbol}, content::Any; dir::String = "") :: Nothing
  open(cache_path(string(key), dir = dir), "w") do io
    Serialization.serialize(io, content)
  end

  nothing
end


"""
    fromcache(key::Union{String,Symbol}, expiration::Int; dir::String = "") :: Union{Nothing,Any}

Retrieves from cache the object stored under the `key` key if the `expiration` delta (in seconds) is in the future.
"""
function fromcache(key::Union{String,Symbol}, expiration::Int; dir::String = "") :: Union{Nothing,Any}
  file_path = cache_path(string(key), dir = dir)

  ( !isfile(file_path) || stat(file_path).ctime + expiration < time() ) && return nothing

  output = open(file_path) do io
    Serialization.deserialize(io)
  end

  output
end


"""
    cache_path(key::Union{String,Symbol}; dir::String = "") :: String

Computes the path to a cache `key` based on current cache settings.
"""
function cache_path(key::Union{String,Symbol}; dir::String = "") :: String
  path = joinpath(Genie.config.path_cache, dir)
  !isdir(path) && mkpath(path)

  joinpath(path, string(key))
end


#===#
# INTERFACE #


"""
    withcache(f::Function, key::Union{String,Symbol}, expiration::Int = Genie.config.cache_duration; dir = "", condition::Bool = true)

Executes the function `f` and stores the result into the cache for the duration (in seconds) of `expiration`. Next time the function is invoked,
if the cache has not expired, the cached result is returned skipping the function execution.
The optional `dir` param is used to designate the folder where the cache will be stored (within the configured cache folder).
If `condition` is `false` caching will be skipped.
"""
function Genie.Cache.withcache(f::Function, key::Union{String,Symbol}, expiration::Int = Genie.config.cache_duration; dir::String = "", condition::Bool = true)
  ( iszero(expiration) || !condition ) && return f()

  cached_data = fromcache(Genie.Cache.cachekey(key), expiration, dir = dir)

  if isnothing(cached_data)
    output = f()
    tocache(Genie.Cache.cachekey(key), output, dir = dir)

    return output
  end

  cached_data
end


"""
    purge(key::Union{String,Symbol}) :: Nothing

Removes the cache data stored under the `key` key.
"""
function Genie.Cache.purge(key::Union{String,Symbol}; dir::String = "") :: Nothing
  rm(cache_path(Genie.Cache.cachekey(key), dir = dir))

  nothing
end


"""
    purgeall(; dir::String = "") :: Nothing

Removes all cached data.
"""
function Genie.Cache.purgeall(; dir::String = "") :: Nothing
  rm(cache_path("", dir = dir), recursive = true)
  mkpath(cache_path("", dir = dir))

  nothing
end

end
