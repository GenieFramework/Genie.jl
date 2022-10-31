# How to control load order of Genie Apps

The default load sequence of Genie Apps is alphabetical i.e.

```
Aab.jl
Abb.jl
Dde.jl
Zyx.jl
```

But sometimes user wants to control the default load order of `.jl` files inside his Genie Apps

### Two ways to control load order in Genie Apps

#### 1) `.autoload_ignore`: 

Taking [ScoringEngineApp](https://github.com/GenieFramework/ScoringEngineApp/tree/master/models), in this app `models/scoringengine/` directory contain bunch of files that are used for model inference and ploting the data. We don't want Genie to load these files automatically during startup, instead we want to manually import these files as to when needed

We can simply achieve this behavior by creating an empty `.autoload_ignore` file in `models/scoringengine` directory and all files contained in this directly are now excluded from Genie's startup load order.

#### 2) `.autoload`

Somtimes we want to sort load order based on our custom preference. For such cases, we use `.autoload` file

Let's assume we have a directory with bunch of `.jl` files as follows

```
Aaa.jl
Abb.jl
Abc.jl
def.jl
Foo.jl
xyz.jl
```

and we want to decide the load order of these files. To achieve this behavior, you can simply create `.autoload` file in the directory containing your `.jl` files with content(developer preferred load order) as follows:

```
xyz.jl
def.jl
Abc.jl
-Foo.jl
```

where `(-)` means exclude the file from Genie's autoload sequence. Now the load order of your directory is going to be

```
xyz.jl
def.jl
Abc.jl
Aaa.jl
Abb.jl
```

