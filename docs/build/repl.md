

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='REPL.secret_token' href='#REPL.secret_token'>#</a>
**`REPL.secret_token`** &mdash; *Function*.



```
secret_token() :: String
```

Generates a random secret token to be used for configuring the SECRET_TOKEN const.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/REPL.jl#L6-L10' class='documenter-source'>source</a><br>

<a id='REPL.new_app' href='#REPL.new_app'>#</a>
**`REPL.new_app`** &mdash; *Function*.



```
new_app(path = ".") :: Void
```

Creates a new Genie app at the indicated path.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/REPL.jl#L16-L20' class='documenter-source'>source</a><br>

<a id='REPL.db_init' href='#REPL.db_init'>#</a>
**`REPL.db_init`** &mdash; *Function*.



```
db_init() :: Bool
```

Sets up the DB tables used by Genie.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/REPL.jl#L35-L39' class='documenter-source'>source</a><br>

<a id='REPL.new_model' href='#REPL.new_model'>#</a>
**`REPL.new_model`** &mdash; *Function*.



```
new_model(model_name) :: Void
```

Creates a new `model` file.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/REPL.jl#L45-L49' class='documenter-source'>source</a><br>

<a id='REPL.new_controller' href='#REPL.new_controller'>#</a>
**`REPL.new_controller`** &mdash; *Function*.



```
new_controller(controller_name) :: Void
```

Creates a new `controller` file.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/REPL.jl#L55-L59' class='documenter-source'>source</a><br>

<a id='REPL.new_resource' href='#REPL.new_resource'>#</a>
**`REPL.new_resource`** &mdash; *Function*.



```
new_resource(resource_name) :: Void
```

Creates all the files associated with a new resource.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/REPL.jl#L65-L69' class='documenter-source'>source</a><br>

<a id='REPL.new_migration' href='#REPL.new_migration'>#</a>
**`REPL.new_migration`** &mdash; *Function*.



```
new_migration(migration_name) :: Void
```

Creates a new migration file.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/REPL.jl#L75-L79' class='documenter-source'>source</a><br>

