module Util

function file_name_to_type_name(file_name)
  file_name_without_extension = replace(file_name, r"\.jl$", "")
  return join(map(x -> ucfirst(x), split(file_name_without_extension, "_")) , "") 
end

function add_quotes(str)
  return "\"$str\""
end

function walk_dir(dir; monitored_extensions = ["jl"])
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

end