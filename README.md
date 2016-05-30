# Genie
### The high-performance high-productivity Julia web framework. 

Genie is a full-stack MVC web framework that provides a streamlined and efficient workflow for developing modern web apps. It builds on top of Julia's strengths (high-level, high-performance, dynamic, JIT compiled, functional), adding a series of modules, methods and tools for highly productive web development. 

## MVC
Genie uses the familiar MVC design pattern. If you have previously used one of the mainstream web frameworks like Rails, Django, Laravel, Phoenix or many others, you'll feel right at home. 

Conceptually, it is designed to expose RESTful representations of the data, organizing an app's entities into self contained resources. 

#### app/
```
├── layouts
└── resources
    ├── packages
    │   ├── authorization.jl
    │   ├── controller.jl
    │   ├── model.jl
    │   ├── validation.jl
    │   └── views
    │       ├── search.json.jl
    │       └── show.json.jl
    └── repos
        ├── model.jl
        ├── validation.jl
        └── views
```
> Structure of two app entities exposed as resources. 
> This resource oriented file structure is a partial implementation of the Trailblazer architecture (http://trailblazer.to/) and it's possible Genie will adopt more of it as it will get more features in the View layer. 

## SearchLight ORM (Model)
Genie provides a powerful ORM named SearchLight, or simply Model. This provides easy, fast and secure access to the underlying database layer. 

SearchLight builds on top of existing powerful Julia data manipulation libraries, DBI and DataFrames. For now it only supports Postgres but support for other DBI enabled backends (MySQL, SQLite) should be very easy to add. 

### Models
Genie makes it simple to define powerful logical wrappers around your data by extending the `Genie.AbstractModel` type. By following a few straightforward conventions, your app's models enherit a wealth of features for validating, persisting, accessing and relating models. 

```julia
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
            has_one = Dict(:has_one_repo => Model.SQLRelation(:Repo, required = false))
          ) = new("packages", "id", id, name, url, has_one) 
end
```

### Query Builder
SearchLight provides an extensive, feature rich, strongly typed query builder. It offers sensible defaults for the most common uses cases, while exposing a comprehensive API for advanced usage. 

```julia
julia> SearchLight.find_one_by(Package, :name, "Mux")
30-May 08:18:57:INFO:console_logger:
SQL QUERY: SELECT "packages"."id" AS "packages_id", "packages"."name" AS "packages_name", "packages"."url" AS "packages_url" FROM "packages" WHERE TRUE AND ( "packages"."name" = ( 'Mux' ) )

  0.000639 seconds (5 allocations: 272 bytes)
30-May 08:18:57:INFO:console_logger:
1×3 DataFrames.DataFrame
│ Row │ packages_id │ packages_name │ packages_url                           │
├─────┼─────────────┼───────────────┼────────────────────────────────────────┤
│ 1   │ 556         │ "Mux"         │ "git://github.com/JuliaWeb/Mux.jl.git" │

Nullable(
Genie.Package
+======+======================================+
|  key |                                value |
+======+======================================+
|   id |                        Nullable(556) |
+------+--------------------------------------+
| name |                                  Mux |
+------+--------------------------------------+
|  url | git://github.com/JuliaWeb/Mux.jl.git |
+------+--------------------------------------+
)
```

```julia
julia> SearchLight.find(Package, SQLQuery(where = SQLWhere(:id, 1000, ">="), order = SQLOrder(:name), limit = 5, offset = 10 ) )
30-May 21:57:43:INFO:console_logger:
SQL QUERY: SELECT "packages"."id" AS "packages_id", "packages"."name" AS "packages_name", "packages"."url" AS "packages_url" FROM "packages" WHERE TRUE AND ( "packages"."id" >= ( 1000 ) ) ORDER BY packages.name ASC LIMIT 5 OFFSET 10

  0.004819 seconds (1.09 k allocations: 43.570 KB)
30-May 21:57:43:INFO:console_logger:
5×3 DataFrames.DataFrame
│ Row │ packages_id │ packages_name       │ packages_url                                             │
├─────┼─────────────┼─────────────────────┼──────────────────────────────────────────────────────────┤
│ 1   │ 1051        │ "AdaGram.jl"        │ "git://github.com/sbos/AdaGram.jl.git"                   │
│ 2   │ 1627        │ "Alg-Jl"            │ "git://github.com/Aurametrix/Alg-Jl.git"                 │
│ 3   │ 1116        │ "AmplNLReader.jl"   │ "git://github.com/JuliaOptimizers/AmplNLReader.jl.git"   │
│ 4   │ 1117        │ "AnimatedPlots.jl"  │ "git://github.com/zyedidia/AnimatedPlots.jl.git"         │
│ 5   │ 1394        │ "AnonymousTypes.jl" │ "git://github.com/MichaelHatherly/AnonymousTypes.jl.git" │

5-element Array{Genie.Package,1}:
[... output omitted ...]
```

```julia
julia> Genie.config.model_relationships_eagerness = MODEL_RELATIONSHIPS_EAGERNESS_EAGER
:eager

julia> SearchLight.find_df(Package, SQLQuery(columns = ["name AS package_name", :url, :updated_at, "repos.fullname AS repo_name"], where = SQLWhere(:updated_at, DateTime(2016), ">="), order = SQLOrder(:name), limit = 5, offset = 10 ) )
30-May 22:02:09:INFO:console_logger:
SQL QUERY: SELECT packages.name AS package_name, packages.url AS packages_url, packages.updated_at AS packages_updated_at, repos.fullname AS repo_name FROM "packages" LEFT JOIN "repos" ON "repos"."package_id" = "packages"."id" WHERE TRUE AND ( "packages"."updated_at" >= ( '2016-01-01T00:00:00' ) ) ORDER BY packages.name ASC LIMIT 5 OFFSET 10

  0.027892 seconds (1.09 k allocations: 43.336 KB)
30-May 22:02:09:INFO:console_logger:
5×4 DataFrames.DataFrame
│ Row │ package_name        │ packages_url                                    │ packages_updated_at          │ repo_name                │
├─────┼─────────────────────┼─────────────────────────────────────────────────┼──────────────────────────────┼──────────────────────────┤
│ 1   │ "ASTInterpreter"    │ "https://github.com/Keno/ASTInterpreter.jl.git" │ "2016-04-16 08:47:43.054054" │ "Keno/ASTInterpreter.jl" │
│ 2   │ "ASTInterpreter.jl" │ "git://github.com/Keno/ASTInterpreter.jl.git"   │ "2016-05-13 11:19:44.869588" │ NA                       │
│ 3   │ "AWS"               │ "git://github.com/amitmurthy/AWS.jl.git"        │ "2016-04-16 08:47:45.810472" │ "amitmurthy/AWS.jl"      │
│ 4   │ "AWSCore"           │ "git://github.com/samoconnor/AWSCore.jl.git"    │ "2016-04-16 08:47:39.674912" │ "samoconnor/AWSCore.jl"  │
│ 5   │ "AWSEC2"            │ "git://github.com/samoconnor/AWSEC2.jl.git"     │ "2016-04-16 08:47:49.192914" │ "samoconnor/AWSEC2.jl"   │
```

### Relationships
... 

### Hydration / dehydration
... 

### Authentication
...

### Authorization
...

## Views
Genie's goal for version 1 is to become a strong alternative for building RESTful APIs and backing SPAs. Thus it provides a simple but powerful and flexible JSON builder. 

Support for rendering HTML views is provided via the `Mustache.jl` package. This is designed mostly to assist with serving simple UIs, like for example the ones that are part of the OAuth process. 

Asset management should be provided by the JavaScript framework employed by the SPA or by a stand-alone JavaScript build tool, such as Brunch (http://brunch.io) or Grunt (http://gruntjs.com). 

The views rendering functionality is provided by the `Renderer` module. 

```julia
p = SearchLight.find_one_by(Package, :id, 42) |> Base. get
Render.respond(Render.json(:packages, :show, package = p))
```
```julia
JSONAPI.builder(
  data = JSONAPI.elem(
    package, :package, 
    type_         = "package", 
    id            = ()-> package.id |> Util.expand_nullable, 
    attributes    = JSONAPI.elem(
      package, 
      name          = ()-> package.name, 
      url           = ()-> package.url, 
      readme        = ()-> Model.relationship_data!(package, :repo, :has_one).readme, 
      participation = ()-> Model.relationship_data!(package, :repo, :has_one).participation 
    ), 
    links = JSONAPI.elem(
      package, 
      self = ()-> "/api/v1/packages/$(package.id |> Util.expand_nullable)"
    )
  )
)
```

> responding with the following JSONAPI.org structured JSON object: 

```json
{
   "data":{
      "type":"package",
      "id":42,
      "links":{
         "self":"/api/v1/packages/42"
      },
      "attributes":{
         "readme":"# Maker\n#### A tool like make for data analysis in Julia\n\n
... 
         The documentation for the development version of this package is \n[here](https://tshort.github.io/Maker.jl/latest/).\n\n",
         "name":"Maker",
         "participation":[
            0,
            0,
...
            0,
            0
         ],
         "url":"git://github.com/tshort/Maker.jl.git"
      }
   }
}
```

## Controllers
Controllers in Genie are just plain julia modules. 

## Router
...

## Channels
...

## App server
...

## Configuration
... 

## Database versioning / Migrations
... 

## Test runner
... 

## Task runner
...

## Logging
... 

## Environments
... 

## Caching
...

## Hosting in production
### Monitoring and restarting Genie apps with Supervisor
### Serving Genie apps with Nginx 
### Parallel execution of Genie apps with Nginx load balancing
### Nginx response caching

##Roadmap (TODOs)
- [ ] more generators: new app, resources, etc. 
- [ ] resourceful routes
- [ ] channels
- [ ] caching