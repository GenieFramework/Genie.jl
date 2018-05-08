module Util

using Genie, Logger, App

export expand_nullable, _!!, _!_, get_nested_field, get_deepest_module, DynamicField, psst, time_to_unixtimestamp, reload

import Base.reload

mutable struct DynamicField{T}
  field::T
end

"""
    add_quotes(str::String) :: String

Adds quotes around `str` and escapes any previously existing quotes.
"""
function add_quotes(str::String) :: String
  if ! startswith(str, "\"")
    str = "\"$str"
  end
  if ! endswith(str, "\"")
    str = "$str\""
  end

  str
end


"""
    strip_quotes(str::String) :: String

Unquotes `str`.
"""
function strip_quotes(str::String) :: String
  if is_quoted(str)
    str[2:end-1]
  else
    str
  end
end


"""
    is_quoted(str::String) :: Bool

Checks weather or not `str` is quoted.
"""
function is_quoted(str::String) :: Bool
  startswith(str, "\"") && endswith(str, "\"")
end


"""
    expand_nullable{T}(value::Nullable{T}, default::T) :: T

Returns `value` if it is not `null` - otherwise `default`.
"""
function expand_nullable{T}(value::T) :: T
  value
end
function expand_nullable{T}(value::Nullable{T}, default::T) :: T
  if isnull(value)
    default
  else
    Base.get(value)
  end
end


"""
    _!!{T}(value::Nullable{T}) :: T

Shortcut for `Base.get(value)`.
"""
function _!!{T}(value::Nullable{T}) :: T
  Base.get(value)
end


"""
    _!_{T}(value::Nullable{T}, default::T) :: T

Shortcut for `expand_nullable(value, default)`.
"""
function _!_{T}(value::Nullable{T}, default::T) :: T
  expand_nullable(value, default)
end


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
function walk_dir(dir, paths = String[]; only_extensions = ["jl"], only_files = true, only_dirs = false) :: Vector{String}
  f = readdir(abspath(dir))
  for i in f
    full_path = joinpath(dir, i)
    if isdir(full_path)
      ! only_files || only_dirs && push!(paths, full_path)
      walk_dir(full_path, paths)
    else
      only_dirs && continue

      (last(split(i, ['.'])) in only_extensions) || isempty(only_extensions) && push!(paths, full_path)
    end
  end

  paths
end


"""
    get_nested_field(path::String, depth::Int = 1, parent::Module) :: DynamicField

Returns the deepest nested field in a `path` of form `Module.Module.Module.function`, wrapped into a `DynamicField`.
"""
function get_nested_field(path::String, depth::Int, parent::Module) :: DynamicField
  parts = split(path, ".")

  new_parent = getfield(parent, Symbol(parts[depth]))

  if length(parts)-1 > depth
    get_nested_field(path, depth+1, new_parent)
  else
    return getfield(new_parent, Symbol(parts[depth+1])) |> DynamicField
  end
end


"""
    get_deepest_module(path::String, depth::Int = 1, parent::Union{Module,Void} = nothing) :: Module

Returns the deepest nested `module` in a `path` of form `Module.Module.Module`.
"""
function get_deepest_module(path::String, depth::Int, parent::Module) :: Module
  parts = split(path, ".")

  new_parent = getfield(parent, Symbol(parts[depth]))

  if length(parts)-2 > depth
    get_deepest_module(path, depth+1, new_parent)
  else
    return new_parent
  end
end


"""
    psst(f::Function)

Invokes `f` while supressing all debugging output for the duration of the invocation.
"""
function psst(f::Function)
  App.config.suppress_output = true
  result = f()
  App.config.suppress_output = false

  result
end


"""
    kill(t::Task) :: Void

Kills `Task` `t` by forcing it to throw an `InterruptException`.
"""
function kill(t::Task) :: Void
  Base.throwto(t, InterruptException())
end


"""
    package_added(pkg_name::String) :: Bool

Checks if the Julia package `pkg_name` has already been added.
"""
function package_added(pkg_name::String) :: Bool
  isdir(Pkg.dir(pkg_name))
end


"""
    reload_modules(dir::String, md::Module = current_module()) :: Bool

Reloads all the modules in the specified `dir` in the scope of `md`.
Returns `true` if any modules were reloaded, `false` otherwise.
"""
function reload_modules(dir::String, md::Module = current_module()) :: Bool
  status = false

  for file in readdir(dir)
    if isfile(joinpath(dir, file)) && endswith(file, ".jl") && isdefined(Symbol(file[1:end-3]))
      eval(md, :(reload("$($file[1:end-3])")) )
      status = true
    end
  end

  status
end


"""
    reload_modules(dirs::Vector{String}, md::Module = current_module()) :: Bool

Reloads all the modules in all the directories specified in `dirs` in the scope of `md`.
Returns `true` if any modules were reloaded, `false` otherwise.
"""
function reload_modules(dirs::Vector{String}, md::Module = current_module()) :: Bool
  status = false

  for dir in dirs
    reload_modules(dir, md) && (status = true)
  end

  status
end


"""

"""
function time_to_unixtimestamp(t::Float64)
  floor(t) |> Int
end
function time_to_unixtimestamp()
  time_to_unixtimestamp(time())
end


"""
"""
function reload(m::Module)
  reload(string(m))
end

end
