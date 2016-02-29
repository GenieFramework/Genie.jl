type Package <: Jinnie_Model
  _table_name::AbstractString
  _id::AbstractString

  id::DbId
  name::AbstractString
  url::AbstractString

  Package(; id = Nullable{Int}(), name = "", url = "") = new("packages", "id", id, name, url) # todo: switch to using symbols or a union type of symbol & string
end

module Packages

using Jinnie

function fullname(p::Jinnie.Package)
  url_parts = split(p.url, '/', keep = false)
  package_name = replace(url_parts[length(url_parts)], r"\.git$", "")
  return url_parts[length(url_parts) - 1] * "/" * package_name
end

end