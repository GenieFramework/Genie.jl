

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='Helpers.session' href='#Helpers.session'>#</a>
**`Helpers.session`** &mdash; *Function*.



```
session() :: Sessions.Session
session(params::Dict{Symbol,Any}) :: Sessions.Session
```

Returns the `Session` object associated with the current HTTP request.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Helpers.jl#L11-L16' class='documenter-source'>source</a><br>

<a id='Helpers.request' href='#Helpers.request'>#</a>
**`Helpers.request`** &mdash; *Function*.



```
request() :: HttpServer.Request
request(params::Dict{Symbol,Any}) :: HttpServer.Request
```

Returns the `Request` object associated with the current HTTP request.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Helpers.jl#L31-L36' class='documenter-source'>source</a><br>

<a id='Helpers.response' href='#Helpers.response'>#</a>
**`Helpers.response`** &mdash; *Function*.



```
response() :: HttpServer.Response
response(params::Dict{Symbol,Any}) :: HttpServer.Response
```

Returns the `Response` object associated with the current HTTP request.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Helpers.jl#L51-L56' class='documenter-source'>source</a><br>

<a id='Helpers.flash' href='#Helpers.flash'>#</a>
**`Helpers.flash`** &mdash; *Function*.



```
flash(params::Dict{Symbol,Any})
```

Returns the `flash` dict object associated with the current HTTP request.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Helpers.jl#L71-L75' class='documenter-source'>source</a><br>


```
flash(value::Any) :: Void
flash(value::Any, params::Dict{Symbol,Any}) :: Void
```

Stores `value` on the `flash`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Helpers.jl#L90-L95' class='documenter-source'>source</a><br>

