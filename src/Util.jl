module Util

using Genie

export expand_nullable, _!!, _!_, get_nested_field, get_deepest_module, DynamicField

type DynamicField{T}
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
    walk_dir(dir; monitored_extensions = ["jl"]) :: String

Recursively walks dir and `produce`s non directories.
"""
function walk_dir(dir; monitored_extensions = ["jl"]) :: String
  f = readdir(abspath(dir))
  for i in f
    full_path = joinpath(dir, i)
    if isdir(full_path)
      walk_dir(full_path)
    else
      if ( last( split(i, ['.']) ) in monitored_extensions )
        produce( full_path )
      end
    end
  end
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

end
