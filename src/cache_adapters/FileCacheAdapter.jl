module FileCacheAdapter

import Revise
import Serialization, Logging
import Genie

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

  ( ! isfile(file_path) || stat(file_path).ctime + expiration < time() ) && return nothing

  Genie.config.log_cache && @info("Hit file system cache for $key at $file_path")

  output = open(file_path) do io
    Serialization.deserialize(io)
  end

  output
end


"""
    purge(key::Union{String,Symbol}) :: Nothing

Removes the cache data stored under the `key` key.
"""
function purge(key::Union{String,Symbol}; dir::String = "") :: Nothing
  rm(cache_path(string(key), dir = dir))

  nothing
end


"""
    purgeall(; dir::String = "") :: Nothing

Removes all cached data.
"""
function purgeall(; dir::String = "") :: Nothing
  rm(cache_path("", dir = dir), recursive = true)
  mkpath(cache_path("", dir = dir))

  nothing
end


"""
    cache_path(key::Union{String,Symbol}; dir::String = "") :: String

Computes the path to a cache `key` based on current cache settings.
"""
function cache_path(key::Union{String,Symbol}; dir::String = "") :: String
  path = joinpath(Genie.CACHE_PATH, dir)
  ! isdir(path) && mkpath(path)

  joinpath(path, string(key))
end

end
