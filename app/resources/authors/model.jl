export Author

type Author <: AbstractModel
  _table_name::AbstractString
  _id::AbstractString

  id::Nullable{Model.DbId}
  name::AbstractString
  fullname::UTF8String
  company::UTF8String
  location::UTF8String
  html_url::AbstractString
  blog_url::AbstractString
  followers_count::Int

  has_many::Array{Model.SQLRelation,1}

  Author(;
    id = Nullable{Model.DbId}(),
    name = "",
    fullname = "",
    company = "",
    location = "",
    html_url = "",
    blog_url = "",
    followers_count = 0,

    has_many = [
                  Model.SQLRelation(Package, eagerness = MODEL_RELATIONSHIPS_EAGERNESS_AUTO),
                  Model.SQLRelation(Repo, join = SQLJoin(Repo, SQLOn("packages.id", "repos.package_id"), join_type = "LEFT" ), eagerness = MODEL_RELATIONSHIPS_EAGERNESS_AUTO)
                ],

  ) = new("authors", "id", id, name, fullname, company, location, html_url, blog_url, followers_count, has_many)
end

module Authors
using Genie
end
