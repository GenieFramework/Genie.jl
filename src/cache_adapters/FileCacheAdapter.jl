module FileCacheAdapter

using Genie, Genie.Loggers


"""
The subfolder under the cache folder where the cache should be stored.
"""
const CACHE_FOLDER = Genie.config.cache_folder


"""
    to_cache(key::Union{String,Symbol}, content::Any; dir = "") :: Nothing

Persists `content` onto the file system under the `key` key.
"""
function to_cache(key::Union{String,Symbol}, content::Any; dir = "") :: Nothing
  open(cache_path(string(key), dir = dir), "w") do io
    serialize(io, content)
  end

  nothing
end


"""
    from_cache(key::Union{String,Symbol}, expiration::Int) :: Nullable

Retrieves from cache the object stored under the `key` key if the `expiration` delta (in seconds) is in the future.
"""
function from_cache(key::Union{String,Symbol}, expiration::Int; dir = "") :: Nullable
  file_path = cache_path(string(key), dir = dir)

  ( ! isfile(file_path) || stat(file_path).ctime + expiration < time() ) && return Nullable()

  Genie.config.log_cache && log("Found file system cache for $key at $file_path", :info)

  output = open(file_path) do io
    deserialize(io)
  end

  Nullable(output)
end


"""
    purge(key::Union{String,Symbol}) :: Nothing

Removes the cache data stored under the `key` key.
"""
function purge(key::Union{String,Symbol}; dir = "") :: Nothing
  rm(cache_path(string(key), dir = dir))

  nothing
end


"""
    purge_all() :: Nothing

Removes all cached data.
"""
function purge_all(; dir = "") :: Nothing
  rm(cache_path("", dir = dir), recursive = true)
  mkpath(cache_path("", dir = dir))
  open(joinpath(cache_path("", dir = dir), ".gitkeep"), "w") do f
    write(f, "")
  end

  nothing
end


"""
    cache_path(key::Union{String,Symbol}; dir = "") :: String

Computes the path to a cache `key` based on current cache settings.
"""
function cache_path(key::Union{String,Symbol}; dir = "") :: String
  path = joinpath(CACHE_FOLDER, dir)
  ! isdir(path) && mkpath(path)

  joinpath(path, string(key))
end

end
