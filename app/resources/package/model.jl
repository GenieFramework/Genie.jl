type Package <: Jinnie_Model
  _table_name::AbstractString
  _id::AbstractString
  name::AbstractString
  url::AbstractString

  Package(; name = "", url = "") = new("packages", "name", name, url)
end