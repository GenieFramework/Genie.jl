

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='Migration.new' href='#Migration.new'>#</a>
**`Migration.new`** &mdash; *Function*.



```
new(migration_name::String, content::String = "") :: Void
new(cmd_args::Dict{String,Any}, config::Configuration.Settings) :: Void
```

Creates a new default migration file and persists it to disk in the configured Genie migrations folder.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L15-L20' class='documenter-source'>source</a><br>

<a id='Migration.migration_hash' href='#Migration.migration_hash'>#</a>
**`Migration.migration_hash`** &mdash; *Function*.



```
migration_hash() :: String
```

Computes a unique hash for a migration identifier.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L54-L58' class='documenter-source'>source</a><br>

<a id='Migration.migration_file_name' href='#Migration.migration_file_name'>#</a>
**`Migration.migration_file_name`** &mdash; *Function*.



```
migration_file_name(migration_name::String) :: String
migration_file_name(cmd_args::Dict{String,Any}, config::Configuration.Settings) :: String
```

Computes the name of a new migration file.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L66-L71' class='documenter-source'>source</a><br>

<a id='Migration.migration_module_name' href='#Migration.migration_module_name'>#</a>
**`Migration.migration_module_name`** &mdash; *Function*.



```
migration_module_name(underscored_migration_name::String) :: String
```

Computes the name of the module of the migration based on the input from the user (migration name).


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L80-L84' class='documenter-source'>source</a><br>

<a id='Migration.last_up' href='#Migration.last_up'>#</a>
**`Migration.last_up`** &mdash; *Function*.



```
last_up() :: Void
```

Migrates up the last migration.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L90-L94' class='documenter-source'>source</a><br>

<a id='Migration.last_down' href='#Migration.last_down'>#</a>
**`Migration.last_down`** &mdash; *Function*.



```
last_down() :: Void
```

Migrates down the last migration.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L100-L104' class='documenter-source'>source</a><br>

<a id='Migration.up_by_module_name' href='#Migration.up_by_module_name'>#</a>
**`Migration.up_by_module_name`** &mdash; *Function*.



```
up_by_module_name(migration_module_name::String; force::Bool = false) :: Void
```

Runs up the migration corresponding to `migration_module_name`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L110-L114' class='documenter-source'>source</a><br>

<a id='Migration.down_by_module_name' href='#Migration.down_by_module_name'>#</a>
**`Migration.down_by_module_name`** &mdash; *Function*.



```
down_by_module_name(migration_module_name::String; force::Bool = false) :: Void
```

Runs down the migration corresponding to `migration_module_name`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L125-L129' class='documenter-source'>source</a><br>

<a id='Migration.migration_by_module_name' href='#Migration.migration_by_module_name'>#</a>
**`Migration.migration_by_module_name`** &mdash; *Function*.



```
migration_by_module_name(migration_module_name::String) :: Nullable{DatabaseMigration}
```

Computes the migration that corresponds to `migration_module_name`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L140-L144' class='documenter-source'>source</a><br>

<a id='Migration.all_migrations' href='#Migration.all_migrations'>#</a>
**`Migration.all_migrations`** &mdash; *Function*.



```
all_migrations() :: Tuple{Vector{String},Dict{String,DatabaseMigration}}
```

Returns the list of all the migrations.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L158-L162' class='documenter-source'>source</a><br>

<a id='Migration.last_migration' href='#Migration.last_migration'>#</a>
**`Migration.last_migration`** &mdash; *Function*.



```
last_migration() :: DatabaseMigration
```

Returns the last created migration.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L178-L182' class='documenter-source'>source</a><br>

<a id='Migration.run_migration' href='#Migration.run_migration'>#</a>
**`Migration.run_migration`** &mdash; *Function*.



```
run_migration(migration::DatabaseMigration, direction::Symbol; force = false) :: Void
```

Runs `migration` in up or down, per `directon`. If `force` is true, the migration is run regardless of its current status (already `up` or `down`).


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L189-L193' class='documenter-source'>source</a><br>

<a id='Migration.store_migration_status' href='#Migration.store_migration_status'>#</a>
**`Migration.store_migration_status`** &mdash; *Function*.



```
store_migration_status(migration::DatabaseMigration, direction::Symbol) :: Void
```

Persists the `direction` of the `migration` into the database.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L220-L224' class='documenter-source'>source</a><br>

<a id='Migration.upped_migrations' href='#Migration.upped_migrations'>#</a>
**`Migration.upped_migrations`** &mdash; *Function*.



```
upped_migrations() :: Vector{String}
```

List of all migrations that are `up`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L236-L240' class='documenter-source'>source</a><br>

<a id='Migration.downed_migrations' href='#Migration.downed_migrations'>#</a>
**`Migration.downed_migrations`** &mdash; *Function*.



```
downed_migrations() :: Vector{String}
```

List of all migrations that are `down`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L248-L252' class='documenter-source'>source</a><br>

<a id='Migration.status' href='#Migration.status'>#</a>
**`Migration.status`** &mdash; *Function*.



```
status() :: Void
```

Prints a table that displays the `direction` of each migration.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L259-L263' class='documenter-source'>source</a><br>

<a id='Migration.all_with_status' href='#Migration.all_with_status'>#</a>
**`Migration.all_with_status`** &mdash; *Function*.



```
all_with_status() :: Tuple{Vector{String},Dict{String,Dict{Symbol,Any}}}
```

Returns a list of all the migrations and their status.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L280-L284' class='documenter-source'>source</a><br>

<a id='Migration.all_down' href='#Migration.all_down'>#</a>
**`Migration.all_down`** &mdash; *Function*.



```
all_down() :: Void
```

Runs all migrations `down`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L304-L308' class='documenter-source'>source</a><br>

<a id='Migration.all_up' href='#Migration.all_up'>#</a>
**`Migration.all_up`** &mdash; *Function*.



```
all_up() :: Void
```

Runs all migrations `up`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/1aab131c148827d91cab858ce55f693885b4501f/src/Migration.jl#L322-L326' class='documenter-source'>source</a><br>

