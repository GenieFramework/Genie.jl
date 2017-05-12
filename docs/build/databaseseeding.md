

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)
    - [Acknowledgements](index.md#Acknowledgements-1)

<a id='DatabaseSeeding.random_seeder' href='#DatabaseSeeding.random_seeder'>#</a>
**`DatabaseSeeding.random_seeder`** &mdash; *Function*.



```
random_seeder(m::Module, quantity = 10, save = false)
```

Generic random database seeder. `m` must expose a `random()` function which returns a SearchLight instance. If `save` the data will be persisted to the database, as configured for the current environment.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/DatabaseSeeding.jl#L11-L16' class='documenter-source'>source</a><br>

