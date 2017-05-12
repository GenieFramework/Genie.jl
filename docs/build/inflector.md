

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='Inflector.to_singular' href='#Inflector.to_singular'>#</a>
**`Inflector.to_singular`** &mdash; *Function*.



```
to_singular(word::String; is_irregular::Bool = false) :: Nullable{String}
```

Returns the singural form of `word`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Inflector.jl#L11-L15' class='documenter-source'>source</a><br>

<a id='Inflector.to_singular_irregular' href='#Inflector.to_singular_irregular'>#</a>
**`Inflector.to_singular_irregular`** &mdash; *Function*.



```
to_singular_irregular(word::String) :: Nullable{String}
```

Returns the singular form of the irregular word `word`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Inflector.jl#L25-L29' class='documenter-source'>source</a><br>

<a id='Inflector.to_plural' href='#Inflector.to_plural'>#</a>
**`Inflector.to_plural`** &mdash; *Function*.



```
to_plural(word::String; is_irregular::Bool = false) :: Nullable{String}
```

Returns the plural form of `word`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Inflector.jl#L40-L44' class='documenter-source'>source</a><br>

<a id='Inflector.to_plural_irregular' href='#Inflector.to_plural_irregular'>#</a>
**`Inflector.to_plural_irregular`** &mdash; *Function*.



```
to_plural_irregular(word::String) :: Nullable{String}
```

Returns the plural form of the irregular word `word`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Inflector.jl#L52-L56' class='documenter-source'>source</a><br>

<a id='Inflector.from_underscores' href='#Inflector.from_underscores'>#</a>
**`Inflector.from_underscores`** &mdash; *Function*.



```
from_underscores(word::String) :: String
```

Generates `SnakeCase` form of `word` from `underscore_case`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Inflector.jl#L67-L71' class='documenter-source'>source</a><br>

<a id='Inflector.is_singular' href='#Inflector.is_singular'>#</a>
**`Inflector.is_singular`** &mdash; *Function*.



```
is_singular(word::String) :: Bool
```

Returns wether or not `word` is a singular.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Inflector.jl#L77-L81' class='documenter-source'>source</a><br>

<a id='Inflector.is_plural' href='#Inflector.is_plural'>#</a>
**`Inflector.is_plural`** &mdash; *Function*.



```
is_plural(word::String) :: Bool
```

Returns wether or not `word` is a plural.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Inflector.jl#L87-L91' class='documenter-source'>source</a><br>

<a id='Inflector.irregulars' href='#Inflector.irregulars'>#</a>
**`Inflector.irregulars`** &mdash; *Function*.



```
irregulars() :: Vector{Tuple{String,String}}
```

Returns a `vector` of words with irregular singular or plural forms.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Inflector.jl#L97-L101' class='documenter-source'>source</a><br>

<a id='Inflector.irregular' href='#Inflector.irregular'>#</a>
**`Inflector.irregular`** &mdash; *Function*.



```
irregular(word::String) :: Nullable{Tuple{String,String}}
```

Wether or not `word` has an irregular singular or plural form.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Inflector.jl#L107-L111' class='documenter-source'>source</a><br>

