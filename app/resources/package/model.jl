type Package <: Jinnie_Model
  _table_name::AbstractString
  _id::AbstractString
  name::AbstractString
  url::AbstractString

  Package(; name = "", url = "") = new("packages", "name", name, url)
end

function fullname(p::Package)
  url_parts = split(p.url, '/', keep = false)
  package_name = replace(url_parts[length(url_parts)], r"\.git$", "")
  return url_parts[length(url_parts) - 1] * "/" * package_name
end