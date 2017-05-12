

- [Genie](index.md#Genie-1)
    - [Quick start](index.md#Quick-start-1)
    - [Next steps](index.md#Next-steps-1)
    - [Acknowledgements](index.md#Acknowledgements-1)

<a id='Tester.bootstrap_tests' href='#Tester.bootstrap_tests'>#</a>
**`Tester.bootstrap_tests`** &mdash; *Function*.



```
bootstrap_tests(cmd_args::String, config::Settings) :: Void
```

Sets up testing environment, includes test files, etc.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Tester.jl#L6-L10' class='documenter-source'>source</a><br>

<a id='Tester.reset_db' href='#Tester.reset_db'>#</a>
**`Tester.reset_db`** &mdash; *Function*.



```
reset_db() :: Void
```

Prepares the test env DB running all migrations up.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Tester.jl#L26-L30' class='documenter-source'>source</a><br>

<a id='Tester.run_all_tests' href='#Tester.run_all_tests'>#</a>
**`Tester.run_all_tests`** &mdash; *Function*.



```
run_all_tests(cmd_args::String, config::Settings) :: Void
```

Runs all existing tests.


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Tester.jl#L39-L43' class='documenter-source'>source</a><br>

<a id='Tester.set_test_env' href='#Tester.set_test_env'>#</a>
**`Tester.set_test_env`** &mdash; *Function*.



```
set_test_env() :: Void
```

Switches Genie to the test env for the duration of the current execution. 


<a target='_blank' href='https://github.com/essenciary/Genie.jl/tree/bbc5671fb81149c8da565a16ed27d1cf7fd2ccfc/src/Tester.jl#L51-L55' class='documenter-source'>source</a><br>

