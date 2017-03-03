module FileCacheAdapter

using Genie

const VALIDITY_START_MARKER = ">>>"
const VALIDITY_END_MARKER   = "<<<"

function write(s::AbstractString) :: Void
  open(cache_path(s), "w") do io
    serialize(io, s)
  end

  nothing
end

function to_cache(key::String, content::Any) :: Void
  open(cache_path(key), "w") do io
    serialize(io, content)
  end

  nothing
end

function from_cache(key::String, expiration::Int) :: Nullable
  file_path = cache_path(key)
  ( ! isfile(file_path) || stat(file_path).ctime + expiration < time() ) && return Nullable()

  output = open(file_path) do io
    deserialize(io)
  end

  Nullable(output)
end

function purge(key::String) :: Void
  rm(cache_path(key))

  nothing
end

function purge_all() :: Void
  rm(cache_path(""), recursive = true)

  nothing
end

function cache_path(key::String) :: String
  joinpath(Genie.config.cache_folder, key)
end

end
