

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)

<a id='Generator.new_model' href='#Generator.new_model'>#</a>
**`Generator.new_model`** &mdash; *Function*.



```
new_model(cmd_args::Dict{String,Any}) :: Void
```

Generates a new SearchLight model file and persists it to the resources folder.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Generator.jl#L9-L13' class='documenter-source'>source</a><br>

<a id='Generator.new_controller' href='#Generator.new_controller'>#</a>
**`Generator.new_controller`** &mdash; *Function*.



```
new_controller(cmd_args::Dict{String,Any}) :: Void
```

Generates a new Genie model file and persists it to the resources folder.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Generator.jl#L28-L32' class='documenter-source'>source</a><br>

<a id='Generator.new_resource' href='#Generator.new_resource'>#</a>
**`Generator.new_resource`** &mdash; *Function*.



```
new_resource(cmd_args::Dict{String,Any}, config::Settings) :: Void
```

Generates all the files associated with a new resource and persists them to the resources folder.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Generator.jl#L66-L70' class='documenter-source'>source</a><br>

<a id='Generator.setup_resource_path' href='#Generator.setup_resource_path'>#</a>
**`Generator.setup_resource_path`** &mdash; *Function*.



```
setup_resource_path(resource_name::String) :: String
```

Computes and creates the directories structure needed to persist a new resource.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Generator.jl#L102-L106' class='documenter-source'>source</a><br>

<a id='Generator.write_resource_file' href='#Generator.write_resource_file'>#</a>
**`Generator.write_resource_file`** &mdash; *Function*.



```
write_resource_file(resource_path::String, file_name::String, resource_name::String) :: Bool
```

Generates all resouce files and persists them to disk.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/61381348076549d7b0c8162b0c07b9b8fbb313c3/src/Generator.jl#L119-L123' class='documenter-source'>source</a><br>

