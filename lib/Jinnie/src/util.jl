module Util

function file_name_to_type_name(file_name)
  file_name_without_extension = replace("packages_import_task.jl", r"\.jl$", "")
  return join(map(x -> ucfirst(x), split(file_name_without_extension, "_")) , "_") 
end

function add_quotes(str)
  return "\"$str\""
end

function add_sql_quotes(str, quote_type = "'")
  return "$quote_type$str$quote_type"
end

end