

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='FileCacheAdapter.to_cache' href='#FileCacheAdapter.to_cache'>#</a>
**`FileCacheAdapter.to_cache`** &mdash; *Function*.



```
to_cache(key::Union{String,Symbol}, content::Any; dir = "") :: Void
```

Persists `content` onto the file system under the `key` key.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/cache_adapters/FileCacheAdapter.jl#L10-L14' class='documenter-source'>source</a><br>

<a id='FileCacheAdapter.from_cache' href='#FileCacheAdapter.from_cache'>#</a>
**`FileCacheAdapter.from_cache`** &mdash; *Function*.



```
from_cache(key::Union{String,Symbol}, expiration::Int) :: Nullable
```

Retrieves from cache the object stored under the `key` key.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/cache_adapters/FileCacheAdapter.jl#L24-L28' class='documenter-source'>source</a><br>

<a id='FileCacheAdapter.purge' href='#FileCacheAdapter.purge'>#</a>
**`FileCacheAdapter.purge`** &mdash; *Function*.



```
purge(key::Union{String,Symbol}) :: Void
```

Removes the cache data stored under the `key` key.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/cache_adapters/FileCacheAdapter.jl#L41-L45' class='documenter-source'>source</a><br>

<a id='FileCacheAdapter.purge_all' href='#FileCacheAdapter.purge_all'>#</a>
**`FileCacheAdapter.purge_all`** &mdash; *Function*.



```
purge_all() :: Void
```

Removes all cached data.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/cache_adapters/FileCacheAdapter.jl#L53-L57' class='documenter-source'>source</a><br>

<a id='FileCacheAdapter.cache_path' href='#FileCacheAdapter.cache_path'>#</a>
**`FileCacheAdapter.cache_path`** &mdash; *Function*.



```
cache_path(key::Union{String,Symbol}; dir = "") :: String
```

Computes the path to a cache `key` based on current cache settings. 


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/cache_adapters/FileCacheAdapter.jl#L65-L69' class='documenter-source'>source</a><br>

