

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='Util.add_quotes' href='#Util.add_quotes'>#</a>
**`Util.add_quotes`** &mdash; *Function*.



```
add_quotes(str::String) :: String
```

Adds quotes around `str` and escapes any previously existing quotes.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Util.jl#L11-L15' class='documenter-source'>source</a><br>

<a id='Util.strip_quotes' href='#Util.strip_quotes'>#</a>
**`Util.strip_quotes`** &mdash; *Function*.



```
strip_quotes(str::String) :: String
```

Unquotes `str`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Util.jl#L28-L32' class='documenter-source'>source</a><br>

<a id='Util.is_quoted' href='#Util.is_quoted'>#</a>
**`Util.is_quoted`** &mdash; *Function*.



```
is_quoted(str::String) :: Bool
```

Checks weather or not `str` is quoted.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Util.jl#L42-L46' class='documenter-source'>source</a><br>

<a id='Util.expand_nullable' href='#Util.expand_nullable'>#</a>
**`Util.expand_nullable`** &mdash; *Function*.



```
expand_nullable{T}(value::Nullable{T}, default::T) :: T
```

Returns `value` if it is not `null` - otherwise `default`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Util.jl#L52-L56' class='documenter-source'>source</a><br>

<a id='Util._!!' href='#Util._!!'>#</a>
**`Util._!!`** &mdash; *Function*.



```
_!!{T}(value::Nullable{T}) :: T
```

Shortcut for `Base.get(value)`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Util.jl#L69-L73' class='documenter-source'>source</a><br>

<a id='Util._!_' href='#Util._!_'>#</a>
**`Util._!_`** &mdash; *Function*.



```
_!_{T}(value::Nullable{T}, default::T) :: T
```

Shortcut for `expand_nullable(value, default)`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Util.jl#L79-L83' class='documenter-source'>source</a><br>

<a id='Util.file_name_without_extension' href='#Util.file_name_without_extension'>#</a>
**`Util.file_name_without_extension`** &mdash; *Function*.



```
file_name_without_extension(file_name, extension = ".jl") :: String
```

Removes the file extension `extension` from `file_name`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Util.jl#L89-L93' class='documenter-source'>source</a><br>

<a id='Util.walk_dir' href='#Util.walk_dir'>#</a>
**`Util.walk_dir`** &mdash; *Function*.



```
walk_dir(dir; monitored_extensions = ["jl"]) :: String
```

Recursively walks dir and `produce`s non directories.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Util.jl#L99-L103' class='documenter-source'>source</a><br>

