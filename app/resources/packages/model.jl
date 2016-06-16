export Package

type Package <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}
  name::AbstractString
  url::AbstractString
  author_id::Nullable{Model.DbId}

  has_one::Array{Model.SQLRelation,1}
  belongs_to::Array{Model.SQLRelation,1}

  Package(; 
            id = Nullable{Model.DbId}(), 
            name = "", 
            url = "", 
            author_id = Nullable{Model.DbId}(), 

            has_one = [Model.SQLRelation(Repo)], 
            belongs_to = [Model.SQLRelation(Author)]
          ) = new("packages", "id", id, name, url, author_id, has_one, belongs_to) 
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

function author(p::Package, a::Author)
  p.author_id = a.id
  p
end

end