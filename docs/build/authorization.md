

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='Authorization.is_authorized' href='#Authorization.is_authorized'>#</a>
**`Authorization.is_authorized`** &mdash; *Function*.



```
is_authorized(ability::Symbol, params::Dict{Symbol,Any}) :: Bool
```

Checks if the user authenticated on the current session (its role) is authorized for `ability` per the corresponding access list.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Authorization.jl#L11-L15' class='documenter-source'>source</a><br>

<a id='Authorization.with_authorization' href='#Authorization.with_authorization'>#</a>
**`Authorization.with_authorization`** &mdash; *Function*.



```
with_authorization(f::Function, ability::Symbol, fallback::Function, params::Dict{Symbol,Any})
```

Invokes `f` if the user authenticatedon the current session is authorized for `ability` - otherwise `fallback` is invoked.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Authorization.jl#L23-L27' class='documenter-source'>source</a><br>

<a id='Authorization.role_has_ability' href='#Authorization.role_has_ability'>#</a>
**`Authorization.role_has_ability`** &mdash; *Function*.



```
role_has_ability(role::Symbol, ability::Symbol, params::Dict{Symbol,Any}) :: Bool
```

Checks if `role` is authorized for `ability`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Authorization.jl#L38-L42' class='documenter-source'>source</a><br>

<a id='Authorization.scopes_of_role_ability' href='#Authorization.scopes_of_role_ability'>#</a>
**`Authorization.scopes_of_role_ability`** &mdash; *Function*.



```
scopes_of_role_ability(role::Symbol, ability::Symbol, params::Dict{Symbol,Any}) :: Vector{Symbol}
```

Returns a `vector` of SQL scopes defined by the role and ability settings.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Authorization.jl#L58-L62' class='documenter-source'>source</a><br>

