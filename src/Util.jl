module Util

import Genie

export expand_nullable, time_to_unixtimestamp



"""
    expand_nullable{T}(value::Union{Nothing,T}, default::T) :: T

Returns `value` if it is not `nothing` - otherwise `default`.
"""
function expand_nullable(value::Union{Nothing,T}, default::T)::T where T
  value === nothing ? default : value
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
  f = readdir(dir)

  for i in f
    full_path = joinpath(dir, i)

    if isdir(full_path)
      (! only_files || only_dirs) && push!(paths, full_path)
      walk_dir(full_path, paths; only_extensions = only_extensions)
    else
      only_dirs && continue

      ((last(split(i, ['.'])) in only_extensions) || isempty(only_extensions)) && push!(paths, full_path)
    end
  end

  paths
end


"""
    time_to_unixtimestamp(t::Float64 = time()) :: Int

Converts a time value to the corresponding unix timestamp.
"""
function time_to_unixtimestamp(t::Float64 = time()) :: Int
  floor(t) |> Int
end


"""
    filterwhitespace(s::String, allowed::Vector{Char} = Char[]) :: String

Removes whitespaces from `s`, whith the exception of the characters in `allowed`.
"""
function filterwhitespace(s::String, allowed::Vector{Char} = Char[]) :: String
  filter(x -> (x in allowed) || ! isspace(x), s)
end

const fws = filterwhitespace

end
