

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)
    - [Acknowledgements](index.md#Acknowledgements-1)

<a id='Toolbox.run_task' href='#Toolbox.run_task'>#</a>
**`Toolbox.run_task`** &mdash; *Function*.



```
run_task(task_type_name)
```

Executes a Genie task.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Toolbox.jl#L12-L16' class='documenter-source'>source</a><br>

<a id='Toolbox.print_all_tasks' href='#Toolbox.print_all_tasks'>#</a>
**`Toolbox.print_all_tasks`** &mdash; *Function*.



```
print_all_tasks() :: Void
```

Prints a list of all the registered Genie tasks to the standard output.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Toolbox.jl#L25-L29' class='documenter-source'>source</a><br>

<a id='Toolbox.all_tasks' href='#Toolbox.all_tasks'>#</a>
**`Toolbox.all_tasks`** &mdash; *Function*.



```
all_tasks(; filter_type_name = Symbol()) :: Vector{TaskInfo}
```

Returns a vector of all registered Genie tasks.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Toolbox.jl#L42-L46' class='documenter-source'>source</a><br>

<a id='Toolbox.new' href='#Toolbox.new'>#</a>
**`Toolbox.new`** &mdash; *Function*.



```
new(cmd_args::Dict{String,Any}, config::Settings) :: Void
```

Generates a new Genie task file.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Toolbox.jl#L70-L74' class='documenter-source'>source</a><br>

<a id='Toolbox.task_file_name' href='#Toolbox.task_file_name'>#</a>
**`Toolbox.task_file_name`** &mdash; *Function*.



```
task_file_name(cmd_args::Dict{String,Any}, config::Settings) :: String
```

Computes the name of a Genie task based on the command line input.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Toolbox.jl#L92-L96' class='documenter-source'>source</a><br>

<a id='Toolbox.task_module_name' href='#Toolbox.task_module_name'>#</a>
**`Toolbox.task_module_name`** &mdash; *Function*.



```
task_module_name(underscored_task_name::String) :: String
```

Computes the name of a Genie task based on the command line input.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Toolbox.jl#L102-L106' class='documenter-source'>source</a><br>

