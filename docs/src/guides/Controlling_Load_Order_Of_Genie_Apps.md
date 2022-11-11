# Controlling load order of julia files in Genie Apps

The default load sequence of julia files in Genie Apps is alphabetical given any directory inside your genie app `plugins`, `libs`, `controllers`. It looks like below:

```
Aab.jl
Abb.jl
Dde.jl
Zyx.jl
```

But sometimes user wants to control the default load order of `.jl` files inside Genie Apps

### Two ways to control load order in Genie Apps

#### 1) `.autoload_ignore`: 

Creating an empty `.autoload_ignore` file in a directory causes all files contained in the folder to be excluded from Genie's startup load order.

#### 2) `.autoload`

Let's assume we have a directory with a few of `.jl` files as follows

```
Aaa.jl
Abb.jl
Abc.jl
def.jl
Foo.jl
-x-yz.jl
```

and we want to decide the load order of these files. To achieve this behavior, we can simply create a `.autoload` file in the directory containing your `.jl` files with content(developer preferred load order) as follows:

```
--x-yz.jl
def.jl
Abc.jl
-Foo.jl
```

where (-) means exclude the file from Genie's autoload sequence and (--) means remove file starting with (-) from Genie Load sequence. Now the load order of our directory is going to be

```
def.jl
Abc.jl
Aaa.jl
Abb.jl
```

