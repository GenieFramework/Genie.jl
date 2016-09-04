module Util

export expand_nullable, _!!, _!_

function add_quotes(str)
  if ! startswith(str, "\"")
    str = "\"$str"
  end
  if ! endswith(str, "\"")
    str = "$str\""
  end

  str
end

function strip_quotes(str)
  if is_quoted(str)
    str[2:end-1]
  else
    str
  end
end

function is_quoted(str)
  startswith(str, "\"") && endswith(str, "\"")
end

function expand_nullable(value::Any; expand::Bool = true, default::Any = "NA")
  if ! expand || ! isa(value, Nullable)
    return value
  end

  if isnull(value)
    default
  else
    Base.get(value)
  end
end

function _!!(value::Any)
  ret = expand_nullable(value)
  ret == "NA" && error("Value $value is NULL")

  ret
end

function _!_(value::Any)
  expand_nullable(value)
end

function file_name_to_type_name(file_name)
  file_name_without_extension = replace(file_name, r"\.jl$", "")
  return join(map(x -> ucfirst(x), split(file_name_without_extension, "_")) , "")
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