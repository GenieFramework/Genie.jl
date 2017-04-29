module FileCacheAdapter

using Genie

const VALIDITY_START_MARKER = ">>>"
const VALIDITY_END_MARKER   = "<<<"
const CACHE_FOLDER = IS_IN_APP ? Genie.config.cache_folder : tempdir()


"""
    to_cache(key::Union{String,Symbol}, content::Any; dir = "") :: Void

Persists `content` onto the file system under the `key` key.
"""
function to_cache(key::Union{String,Symbol}, content::Any; dir = "") :: Void
  open(cache_path(string(key), dir = dir), "w") do io
    serialize(io, content)
  end

  nothing
end


"""
    from_cache(key::Union{String,Symbol}, expiration::Int) :: Nullable

Retrieves from cache the object stored under the `key` key.
"""
function from_cache(key::Union{String,Symbol}, expiration::Int) :: Nullable
  file_path = cache_path(string(key))
  ( ! isfile(file_path) || stat(file_path).ctime + expiration < time() ) && return Nullable()

  output = open(file_path) do io
    deserialize(io)
  end

  Nullable(output)
end


"""
    purge(key::Union{String,Symbol}) :: Void

Removes the cache data stored under the `key` key.
"""
function purge(key::Union{String,Symbol}) :: Void
  rm(cache_path(string(key)))

  nothing
end


"""
    purge_all() :: Void

Removes all cached data.
"""
function purge_all() :: Void
  rm(cache_path(""), recursive = true)

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
