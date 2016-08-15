module FileCacheAdapter

using Genie

function write(s::AbstractString)
  open(cache_path(s), "w") do (io)
    serialize(io, s)
  end
end

end