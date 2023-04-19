module Util

import Genie


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
                  only_extensions = ["jl"], only_files = true, only_dirs = false,
                  exceptions = Genie.config.watch_exceptions,
                  autoload_ignorefile = Genie.config.autoload_ignore_file) :: Vector{String}
  f = readdir(dir)

  exception = false
  for i in f
    full_path = joinpath(dir, i)

    for ex in exceptions
      if occursin(ex, full_path)
        exception = true
        break
      end
    end

    if exception
      exception = false
      continue
    end

    if isdir(full_path)
      isfile(joinpath(full_path, autoload_ignorefile)) && continue
      (! only_files || only_dirs) && push!(paths, full_path)
      Genie.Util.walk_dir(full_path, paths; only_extensions = only_extensions, only_files = only_files, only_dirs = only_dirs, exceptions = exceptions, autoload_ignorefile = autoload_ignorefile)
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

const fws = filterwhitespace

end
