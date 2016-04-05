type Package <: JinnieModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}
  name::AbstractString
  url::AbstractString

  has_one::Nullable{Array{Model.SQLRelation, 1}}

  Package(; 
            id = Nullable{Model.DbId}(), 
            name = "", 
            url = "", 
            has_one = [Model.SQLRelation(:repo, required = false)]) = 
        new("packages", "id", id, name, url, has_one) 
end

module Packages

using Jinnie

function fullname(p::Jinnie.Package)
  url_parts = split(p.url, '/', keep = false)
  package_name = replace(url_parts[length(url_parts)], r"\.git$", "")
  return url_parts[length(url_parts) - 1] * "/" * package_name
end

end