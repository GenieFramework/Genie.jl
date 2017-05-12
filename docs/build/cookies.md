

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='Cookies.get' href='#Cookies.get'>#</a>
**`Cookies.get`** &mdash; *Function*.



```
get(res::Response, key::Union{String,Symbol}) :: Nullable{String}
```

Retrieves a value stored on the cookie as `key` from the `Respose` object.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Cookies.jl#L9-L13' class='documenter-source'>source</a><br>


```
get(req::Request, key::Union{String,Symbol}) :: Nullable{String}
```

Retrieves a value stored on the cookie as `key` from the `Request` object.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Cookies.jl#L23-L27' class='documenter-source'>source</a><br>

<a id='Cookies.set!' href='#Cookies.set!'>#</a>
**`Cookies.set!`** &mdash; *Function*.



```
set!(res::Response, key::Union{String,Symbol}, value::Any, attributes::Dict) :: Dict{String,HttpCommon.Cookie}
set!(res::Response, key::Union{AbstractString,Symbol}, value::Any) :: Dict{String,HttpCommon.Cookie}
```

Sets `value` under the `key` label on the `Cookie`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Cookies.jl#L40-L45' class='documenter-source'>source</a><br>

<a id='Cookies.to_dict' href='#Cookies.to_dict'>#</a>
**`Cookies.to_dict`** &mdash; *Function*.



```
to_dict(req::Request) :: Dict{String,String}
```

Extracts the `Cookie` data from the `Request` and converts it into a dict.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Cookies.jl#L56-L60' class='documenter-source'>source</a><br>

