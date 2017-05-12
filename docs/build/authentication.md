

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='Authentication.authenticate' href='#Authentication.authenticate'>#</a>
**`Authentication.authenticate`** &mdash; *Function*.



```
authenticate(user_id::Union{String,Symbol,Int}, session) :: Sessions.Session
authenticate(user_id::Union{String,Symbol,Int}, params::Dict{Symbol,Any}) :: Sessions.Session
```

Stores the user id on the session.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Authentication.jl#L13-L18' class='documenter-source'>source</a><br>

<a id='Authentication.deauthenticate' href='#Authentication.deauthenticate'>#</a>
**`Authentication.deauthenticate`** &mdash; *Function*.



```
deauthenticate(session) :: Sessions.Session
deauthenticate(params::Dict{Symbol,Any}) :: Sessions.Session
```

Removes the user id from the session.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Authentication.jl#L27-L32' class='documenter-source'>source</a><br>

<a id='Authentication.is_authenticated' href='#Authentication.is_authenticated'>#</a>
**`Authentication.is_authenticated`** &mdash; *Function*.



```
is_authenticated(session) :: Bool
is_authenticated(params::Dict{Symbol,Any}) :: Bool
```

Returns `true` if a user id is stored on the session.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Authentication.jl#L41-L46' class='documenter-source'>source</a><br>

<a id='Authentication.get_authentication' href='#Authentication.get_authentication'>#</a>
**`Authentication.get_authentication`** &mdash; *Function*.



```
get_authentication(session) :: Nullable
get_authentication(params::Dict{Symbol,Any}) :: Nullable
```

Returns the user id stored on the session, if available.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Authentication.jl#L55-L60' class='documenter-source'>source</a><br>

<a id='Authentication.login' href='#Authentication.login'>#</a>
**`Authentication.login`** &mdash; *Function*.



```
login(user, session) :: Nullable{Sessions.Session}
login(user, params::Dict{Symbol,Any}) :: Nullable{Sessions.Session}
```

Persists on session the id of the user object and returns the session.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Authentication.jl#L69-L74' class='documenter-source'>source</a><br>

<a id='Authentication.logout' href='#Authentication.logout'>#</a>
**`Authentication.logout`** &mdash; *Function*.



```
logout(session) :: Sessions.Session
logout(params::Dict{Symbol,Any}) :: Sessions.Session
```

Deletes the id of the user object from the session, effectively logging the user off.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Authentication.jl#L83-L88' class='documenter-source'>source</a><br>

<a id='Authentication.current_user' href='#Authentication.current_user'>#</a>
**`Authentication.current_user`** &mdash; *Function*.



```
current_user(session) :: Nullable{User}
current_user(params::Dict{Symbol,Any}) :: Nullable{User}
```

Returns the `User` instance corresponding to the currently authenticated user, wrapped into a Nullable.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Authentication.jl#L97-L102' class='documenter-source'>source</a><br>

<a id='Authentication.current_user!!' href='#Authentication.current_user!!'>#</a>
**`Authentication.current_user!!`** &mdash; *Function*.



```
current_user!!(session) :: User
current_user!!(params::Dict{Symbol,Any}) :: User
```

Attempts to get the `User` instance corresponding to the currently authenticated user - throws error on failure.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Authentication.jl#L116-L121' class='documenter-source'>source</a><br>

<a id='Authentication.with_authentication' href='#Authentication.with_authentication'>#</a>
**`Authentication.with_authentication`** &mdash; *Function*.



```
with_authentication(f::Function, fallback::Function, session)
with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})
```

Invokes `f` only if a user is currently authenticated on the session, `fallback` is invoked otherwise.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Authentication.jl#L137-L142' class='documenter-source'>source</a><br>

<a id='Authentication.without_authentication' href='#Authentication.without_authentication'>#</a>
**`Authentication.without_authentication`** &mdash; *Function*.



```
without_authentication(f::Function, session)
without_authentication(f::Function, params::Dict{Symbol,Any})
```

Invokes `f` if there is no user authenticated on the current session.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Authentication.jl#L155-L160' class='documenter-source'>source</a><br>

