module Util

using Pkg
import Genie

export project_path, @project_path

"""
    file_name_without_extension(file_name, extension = ".jl") :: String

Removes the file extension `extension` from `file_name`.
"""
function file_name_without_extension(file_name, extension = ".jl") :: String
  file_name[1:end-length(extension)]
end


"""
    function walk_dir(dir, paths = String[]; only_extensions = ["jl"], only_files = true, only_dirs = false) :: Vector{String}

Recursively walks dir and `produce`s non directories. If `only_files`, directories will be skipped. If `only_dirs`, files will be skipped.
"""
function walk_dir(dir, paths = String[];
                  only_extensions = ["jl"],
                  only_files = true,
                  only_dirs = false,
                  exceptions = Genie.config.watch_exceptions,
                  autoload_ignorefile = Genie.config.autoload_ignore_file,
                  test_function::Union{Function,Nothing} = nothing
                ) :: Vector{String}
  f = readdir(dir)

  for i in f
    full_path = joinpath(dir, i)

    for ex in exceptions
      if occursin(ex, full_path)
        continue
      end
    end

    if test_function !== nothing
      test_function(full_path) || continue
    end

    if isdir(full_path)
      isfile(joinpath(full_path, autoload_ignorefile)) && continue
      (! only_files || only_dirs) && push!(paths, full_path)
      Genie.Util.walk_dir(full_path, paths;
                          only_extensions = only_extensions,
                          only_files = only_files,
                          only_dirs = only_dirs,
                          exceptions = exceptions,
                          autoload_ignorefile = autoload_ignorefile,
                          test_function = test_function
                        )
    else
      only_dirs && continue

      ((last(split(i, ['.'])) in only_extensions) || isempty(only_extensions)) && push!(paths, full_path)
    end
  end

  paths
end
const walkdir = walk_dir


"""
    filterwhitespace(s::String, allowed::Vector{Char} = Char[]) :: String

Removes whitespaces from `s`, with the exception of the characters in `allowed`.
"""
function filterwhitespace(s::S, allowed::Vector{Char} = Char[])::String where {S<:AbstractString}
  filter(x -> (x in allowed) || ! isspace(x), string(s))
end


"""
    isprecompiling() :: Bool

Returns `true` if the current process is precompiling.
"""
isprecompiling() = ccall(:jl_generating_output, Cint, ()) == 1


const fws = filterwhitespace

"""
    package_version(package::Union{Module,String}) :: String

Returns the version of a package, or "master" if the package is not installed.

### Example

```julia

julia> package_version("Genie.jl")
"v0.23.0"
"""
function package_version(package::Union{Module,String}) :: String
  isa(package, Module) && (package = String(nameof(package)))
  endswith(package, ".jl") && (package = String(package[1:end-3]))
  pkg_dict = filter(x -> x.second.name == package, Pkg.dependencies())
  isempty(pkg_dict) ? "master" : ("v" * string(first(pkg_dict)[2].version))
end

function expr_to_path(expr::Union{Expr, Symbol, String})::String
  path = String[]
  while expr isa Expr && expr.head == :call && expr.args[1] ∈ (:\, :/)
      push!(path, string(expr.args[3]))
      expr = expr.args[2]
  end
  push!(path, string(expr))
  return join(reverse(path), '/')
end

"""
    function project_path(path = pwd(), error_if_not_found = true) :: String

Returns the path to the project directory of `path`.
If `error_if_not_found` is `false`, the current working directory is returned if no project directory could be found.

The macro version `@project_path` returns the project path of the current file.
"""
function project_path(path = pwd(); error_if_not_found = true)::String
  orig_path = path
  isabspath(path) || (path = normpath(joinpath(pwd(), path)))
  while !isfile(joinpath(path, "Project.toml"))
    newpath = dirname(path)
    if newpath == path
        if error_if_not_found
            error("Could not find Project.toml in any parent directory of '$path'")
        else
            return pwd()
        end
    end
    path = newpath
  end
  return path
end

"""
    @project_path

Returns the path to the project directory of the current file.

    @project_path path

Returns the absolute path of a file or directory within the project directory of the current file.

### Examples

```julia
@project_path
# "/path/to/project"

@project_path db/connection.yml
# "/path/to/project/db/connection.yml"
```
Paths can be given without double quotes if no special characters are present.
The determination of the project folder is done by searching for the `Project.toml`
file in the file's directory and its parents.

Background:

Since Julia v1.11.6 precompilation is no longer executed in the directory of the
package but in a temporary directory. If it is intended to 
precompile the Genie app all paths that are executed during compile time need to
be changed to absolute paths.

This macro is intended to simplify the transition to absolute paths.
"""
macro project_path()
  project_path(dirname(String(__source__.file)))
end

macro project_path(path)
    path = expr_to_path(path)
    Sys.iswindows() && (path = replace(path, '/' => '\\'))

    d = project_path(dirname(String(__source__.file)))
    return joinpath(d, path)
end

end
