type Package <: Jinnie_Model
  _table_name::AbstractString
  _id::AbstractString
  _id_unset_value::Int

  id::Int
  name::AbstractString
  url::AbstractString

  Package(; id = -1, name = "", url = "") = new("packages", "id", -1, id, name, url) # todo: switch to using symbols or a union type of symbol & string
end

function fullname(p::Package)
  url_parts = split(p.url, '/', keep = false)
  package_name = replace(url_parts[length(url_parts)], r"\.git$", "")
  return url_parts[length(url_parts) - 1] * "/" * package_name
end

function rand(p::Type{Jinnie.Package})
  df = Model.find(p(), limit = "1", order = "random()")
  return Model.df_to_m(df, p())[1]
end