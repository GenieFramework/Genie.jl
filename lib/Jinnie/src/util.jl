module Util

function file_name_to_type_name(file_name)
  file_name_without_extension = replace(file_name, r"\.jl$", "")
  return join(map(x -> ucfirst(x), split(file_name_without_extension, "_")) , "_") 
end

function add_quotes(str)
  return "\"$str\""
end

end