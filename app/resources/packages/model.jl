export Package

type Package <: Genie.AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}
  name::AbstractString
  url::AbstractString

  has_one::Nullable{Dict{Symbol, Model.SQLRelation}}

  Package(; 
            id = Nullable{Model.DbId}(), 
            name = "", 
            url = "", 
            has_one = Dict(:has_one_repo => Model.SQLRelation(:Repo, eagerness = MODEL_RELATIONSHIPS_EAGERNESS_LAZY))
          ) = new("packages", "id", id, name, url, has_one) 
end
function Package(name::AbstractString, url::AbstractString) 
  p = Package()
  p.name = name
  p.url = url

  p
end

module Packages

using Genie

function fullname(p::Package)
  url_parts = split(p.url, '/', keep = false)
  package_name = replace(url_parts[length(url_parts)], r"\.git$", "")

  url_parts[length(url_parts) - 1] * "/" * package_name
end

end