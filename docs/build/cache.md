

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)
    - [Acknowledgements](index.md#Acknowledgements-1)

<a id='Cache.with_cache' href='#Cache.with_cache'>#</a>
**`Cache.with_cache`** &mdash; *Function*.



```
with_cache(f::Function, key::String, expiration::Int = CACHE_DURATION; dir = "", condition::Bool = true)
```

Executes the function `f` and stores the result into the cache for the duration of `expiration`. Next time the function is invoked, if the cache has not expired, the cached result is returned skipping the function execution. The optional `dir` param is used to designate the folder where the cache will be stored (within the configured cache folder). If `condition` is `false` caching will be skipped.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Cache.jl#L25-L32' class='documenter-source'>source</a><br>

<a id='Cache.cache_key' href='#Cache.cache_key'>#</a>
**`Cache.cache_key`** &mdash; *Function*.



```
cache_key(args...) :: String
```

Computes a unique cache key based on `args`. Used to generate unique `key`s for storing data in cache.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Cache.jl#L52-L56' class='documenter-source'>source</a><br>

<a id='Cache.cache_adapter' href='#Cache.cache_adapter'>#</a>
**`Cache.cache_adapter`** &mdash; *Function*.



```
cache_adapter(adapter::Symbol = Genie.config.cache_adapter) :: Module
```

Returns the currently active cache adapter, as defined in the settings.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Cache.jl#L67-L71' class='documenter-source'>source</a><br>

