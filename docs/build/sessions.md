

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='Sessions.id' href='#Sessions.id'>#</a>
**`Sessions.id`** &mdash; *Function*.



```
id() :: String
id(req::Request) :: String
id(req::Request, res::Response) :: String
```

Generates a unique session id.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Sessions.jl#L20-L26' class='documenter-source'>source</a><br>

<a id='Sessions.start' href='#Sessions.start'>#</a>
**`Sessions.start`** &mdash; *Function*.



```
start(session_id::String, req::Request, res::Response; options = Dict{String,String}()) :: Session
start(req::Request, res::Response) :: Session
```

Initiates a session.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Sessions.jl#L56-L61' class='documenter-source'>source</a><br>

<a id='Sessions.set!' href='#Sessions.set!'>#</a>
**`Sessions.set!`** &mdash; *Function*.



```
set!(s::Session, key::Symbol, value::Any) :: Session
```

Stores `value` as `key` on the `Session` `s`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Sessions.jl#L73-L77' class='documenter-source'>source</a><br>

<a id='Sessions.get' href='#Sessions.get'>#</a>
**`Sessions.get`** &mdash; *Function*.



```
get(s::Session, key::Symbol) :: Nullable
```

Returns the value stored on the `Session` `s` as `key`, wrapped in a `Nullable`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Sessions.jl#L85-L89' class='documenter-source'>source</a><br>

<a id='Sessions.get!!' href='#Sessions.get!!'>#</a>
**`Sessions.get!!`** &mdash; *Function*.



```
get!!(s::Session, key::Symbol)
```

Attempts to read the value stored on the `Session` `s` as `key` - throws an exception if the `key` does not exist.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Sessions.jl#L99-L103' class='documenter-source'>source</a><br>

<a id='Sessions.unset!' href='#Sessions.unset!'>#</a>
**`Sessions.unset!`** &mdash; *Function*.



```
unset!(s::Session, key::Symbol) :: Session
```

Removes the value stored on the `Session` `s` as `key`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Sessions.jl#L109-L113' class='documenter-source'>source</a><br>

<a id='Sessions.is_set' href='#Sessions.is_set'>#</a>
**`Sessions.is_set`** &mdash; *Function*.



```
is_set(s::Session, key::Symbol) :: Bool
```

Checks wheter or not `key` exists on the `Session` `s`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Sessions.jl#L121-L125' class='documenter-source'>source</a><br>

<a id='Sessions.persist' href='#Sessions.persist'>#</a>
**`Sessions.persist`** &mdash; *Function*.



```
persist(s::Session) :: Session
```

Generic method for persisting session data - delegates to the underlying `SessionAdapter`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Sessions.jl#L131-L135' class='documenter-source'>source</a><br>

<a id='Sessions.load' href='#Sessions.load'>#</a>
**`Sessions.load`** &mdash; *Function*.



```
load(session_id::String) :: Session
```

Loads session data from persistent storage - delegates to the underlying `SessionAdapter`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Sessions.jl#L143-L147' class='documenter-source'>source</a><br>

