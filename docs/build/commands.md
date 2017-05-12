

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)
    - [Acknowledgements](index.md#Acknowledgements-1)

<a id='Commands.execute' href='#Commands.execute'>#</a>
**`Commands.execute`** &mdash; *Function*.



```
execute(config::Settings) :: Void
```

Runs the requested Genie app command, based on the `args` passed to the script.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Commands.jl#L9-L13' class='documenter-source'>source</a><br>

<a id='Commands.parse_commandline_args' href='#Commands.parse_commandline_args'>#</a>
**`Commands.parse_commandline_args`** &mdash; *Function*.



```
parse_commandline_args() :: Dict{AbstractString,Any}
```

Extracts the command line args passed into the app and returns them as a `Dict`, possibly setting up defaults. Also, it is used by the ArgParse module to populate the command line help for the app `-h`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Commands.jl#L83-L88' class='documenter-source'>source</a><br>

<a id='Commands.check_valid_task!' href='#Commands.check_valid_task!'>#</a>
**`Commands.check_valid_task!`** &mdash; *Function*.



```
check_valid_task!(parsed_args::Dict{AbstractString,Any}) :: Dict{AbstractString,Any}
```

Checks if the name of the task passed as the command line arg is valid task identifier – if not, attempts to address it, by appending the "Task" suffix. Returns the potentially modified `parsed_args` `Dict`.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Commands.jl#L169-L174' class='documenter-source'>source</a><br>

<a id='Commands.called_command' href='#Commands.called_command'>#</a>
**`Commands.called_command`** &mdash; *Function*.



```
called_command(args::Dict, key::String) :: Bool
```

Checks whether or not a certain command was invoked by looking at the command line args.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Commands.jl#L183-L187' class='documenter-source'>source</a><br>

