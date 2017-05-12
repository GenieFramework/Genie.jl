

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)
    - [Acknowledgements](index.md#Acknowledgements-1)

<a id='App.load_models' href='#App.load_models'>#</a>
**`App.load_models`** &mdash; *Function*.



```
load_models(dir = Genie.RESOURCE_PATH) :: Void
```

Loads (includes) all available `model` and `validator` files. The modules are included in the `App` module.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/App.jl#L11-L16' class='documenter-source'>source</a><br>

<a id='App.load_controller' href='#App.load_controller'>#</a>
**`App.load_controller`** &mdash; *Function*.



```
load_controller(dir::String) :: Void
```

Loads (includes) the `controller` file that corresponds to the currently matched route. The modules are included in the `App` module.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/App.jl#L38-L43' class='documenter-source'>source</a><br>

<a id='App.export_controllers' href='#App.export_controllers'>#</a>
**`App.export_controllers`** &mdash; *Function*.



```
export_controllers(controllers::String) :: Void
```

Make `controller` modules available autside the `App` module.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/App.jl#L68-L72' class='documenter-source'>source</a><br>

<a id='App.load_acl' href='#App.load_acl'>#</a>
**`App.load_acl`** &mdash; *Function*.



```
load_acl(dir::String) :: Dict{Any,Any}
```

Loads the ACL file associated with the invoked `controller` and returns the rules.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/App.jl#L92-L96' class='documenter-source'>source</a><br>

<a id='App.load_configurations' href='#App.load_configurations'>#</a>
**`App.load_configurations`** &mdash; *Function*.



```
load_configurations() :: Void
```

Loads (includes) the framework's configuration files.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/App.jl#L103-L107' class='documenter-source'>source</a><br>

<a id='App.load_initializers' href='#App.load_initializers'>#</a>
**`App.load_initializers`** &mdash; *Function*.



```
load_initializers() :: Void
```

Loads (includes) the framework's initializers.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/App.jl#L116-L120' class='documenter-source'>source</a><br>

