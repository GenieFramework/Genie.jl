export Package

type Package <: Genie.GenieModel
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
            has_one = Dict(:has_one_repo => Model.SQLRelation(:repo, required = false, lazy = true))
          ) = new("packages", "id", id, name, url, has_one) 
end

module Packages

using Genie

function fullname(p::Package)
  url_parts = split(p.url, '/', keep = false)
  package_name = replace(url_parts[length(url_parts)], r"\.git$", "")

  url_parts[length(url_parts) - 1] * "/" * package_name
end

end