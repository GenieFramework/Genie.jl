module FileCacheAdapter
using Genie

const VALIDITY_START_MARKER = ">>>"
const VALIDITY_END_MARKER   = "<<<"

function write(s::AbstractString)
  open(cache_path(s), "w") do io
    serialize(io, s)
  end
end

function to_cache(key::ASCIIString, content)
  open(cache_path(key), "w") do io
    serialize(io, content)
  end
end

function from_cache(key::ASCIIString, expiration::Int)
  file_path = cache_path(key)
  ( ! isfile(file_path) || ! isreadable(file_path) || stat(file_path).ctime + expiration < time() ) && return Nullable()

  output = open(file_path) do io
    deserialize(io)
  end

  Nullable(output)
end

function purge(key::ASCIIString)
  rm(cache_path(key))
end

function purge_all()
  rm(cache_path(""), recursive = true)
end

function cache_path(key::ASCIIString)
  joinpath(Genie.config.cache_folder, key)
end

end