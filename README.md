![Genie Logo](https://dl.dropboxusercontent.com/s/0dbiza50r63cvvc/genie_logo.png)

# Genie
### High-performance high-productivity Julia web framework. 

Genie is a full-stack MVC web framework that provides a streamlined and efficient workflow for developing modern web applications. It builds on top of Julia's (julialang.org) strengths (high-level, high-performance, dynamic, JIT compiled, functional programming language), adding a series of modules, methods and tools for promoting productive web development. 

In order to start a Genie interactive session at the Julia REPL, just type 
```
$> julia -L genie.jl --color=yes -q
```

## MVC
Genie uses the familiar MVC design pattern. If you have previously used one of the mainstream web frameworks like Rails, Django, Laravel, Phoenix, to name a few, you'll feel right at home. 

Conceptually, it is designed to expose RESTful representations of the data, organizing an app's business objects into self contained resources. A resource is an object with a type, associated data, relationships to other resources, and a set of methods that operate on it.

##### app/
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
> Structure of two business objects ("packages" and "repos") modeled as resources. 

## SearchLight ORM (Model)
Genie provides a powerful ORM named SearchLight. It offers easy, fast and secure access to the underlying database layer. 

SearchLight uses existing powerful Julia data manipulation libraries, like `DBI` and `DataFrames`. For now it only supports PostgreSQL (through `PostgreSQL.jl`) but support for other DBI compatible backends (MySQL, SQLite) should be very easy to add. 

### Models
Genie makes it simple to define powerful logical wrappers around your data by extending the `Genie.AbstractModel` type and by following a few straightforward conventions. This way your app's models will inherit a wealth of features for validating, persisting, accessing and relating models. 

The conventions that **must** be follwed by your models in order to be SearchLight compatible are: 

* must be a concrete type that inherits from `Genie.AbstractModel`
* must define two properties, `_table_name::AbstractString` and `_id::AbstractString` that will provide Genie information about the underlying database table. `_table_name::AbstractString` is of course the name of the table, while `_id::AbstractString` is the name of the `primary key` (`PK`) column
* the models' concrete types can not be included in another module, they must be defined at the top level of the corresponding `model.jl` file. (This restriction will most likely go away in a future version for better encapsulation and for allowing multiple apps without name clashes - but for now it's a requirement)
* the models must define a zero arguments default constructor

##### app/resources/packages/model.jl

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
            has_one = Dict(:has_one_repo => Model.SQLRelation(:Repo, eagerness = MODEL_RELATIONSHIPS_EAGERNESS_LAZY))
          ) = new("packages", "id", id, name, url, has_one) 
end
```

As this is just a Julia concrete type after all, you can add other convenience constructors. 

##### Recommended code style 
The model's type name should be a noun used with the singular form (`Package`, `Repo`, etc). 

All the methods operating upon the model's type should be contained in a module named the same as the type but using the plural form (`module Packages`, `module Repos`, etc)

```julia
export Package

type Package <: Genie.AbstractModel
[ ... code omitted ... ]
end
function Package(name::AbstractString, url::AbstractString) 
[ ... code omitted ... ]
end

module Packages

using Genie

function fullname(p::Package)
[ ... code omitted ... ]
end

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

Persistance functionality is also included, `save` being the basic method. 

```julia
julia> using Genie, Model

julia> p = Package("PkgSearch", "https://github.com/essenciary/pkg_search")

Genie.Package
+======+==========================================+
|  key |                                    value |
+======+==========================================+
|   id |                        Nullable{Int32}() |
+------+------------------------------------------+
| name |                                PkgSearch |
+------+------------------------------------------+
|  url | https://github.com/essenciary/pkg_search |
+------+------------------------------------------+

julia> SearchLight.save(p)
31-May 18:42:26:INFO:console_logger:
SQL QUERY: INSERT INTO packages ( "name", "url" ) VALUES ( 'PkgSearch', 'https://github.com/essenciary/pkg_search' ) RETURNING id

  0.001744 seconds (4 allocations: 224 bytes)
  
31-May 18:42:26:INFO:console_logger:
1×1 DataFrames.DataFrame
│ Row │ id   │
├─────┼──────┤
│ 1   │ 1715 │

true
```

### Relationships
SearchLight allows models to define mutual relationships. These are the standard types of relationships from the ORM world: `belongs_to`, `has_one`, `has_many`, `has_one_through`, `has_many_through`. (Still debating whether or not `has_and_belongs_to_many` should be also included). 

```julia
type Package <: Genie.AbstractModel
  [ ... code omitted ... ]
  has_one::Nullable{Dict{Symbol, Model.SQLRelation}}
  Package(; 
			[ ... code omitted ... ]
            has_one = Dict(:has_one_repo => Model.SQLRelation(:Repo, eagerness = MODEL_RELATIONSHIPS_EAGERNESS_LAZY))  
          ) = new("packages", "id", id, name, url, has_one) 
end
```

```julia
type Repo <: AbstractModel
  [ ... code omitted ... ]
  belongs_to::Nullable{Dict{Symbol, Model.SQLRelation}}
  Repo(; 
        [ ... code omitted ... ]
        belongs_to = Dict(:belongs_to_package => Model.SQLRelation(:Package))
      ) = new("repos", "id", github, id, package_id, fullname, readme, participation, updated_at, belongs_to, on_dehydration, on_hydration)
end
```

If the relationship is *eager*, the underlying tables are automatically joined upon the retrieval of any of the models and all the corresponding data is `SELECT`ed and the corresponding types instantiated. If the relationship is *lazy*, the data is brought from the database on demand, when you try to get the related data for the first time. 

```julia
julia> p = SearchLight.rand(Package) |> first

31-May 19:46:20:INFO:console_logger:
SQL QUERY: SELECT "packages"."id" AS "packages_id", "packages"."name" AS "packages_name", "packages"."url" AS "packages_url" FROM "packages" ORDER BY random() ASC LIMIT 1

  0.002107 seconds (5 allocations: 272 bytes)

31-May 19:46:20:INFO:console_logger:
1×3 DataFrames.DataFrame
│ Row │ packages_id │ packages_name │ packages_url                           │
├─────┼─────────────┼───────────────┼────────────────────────────────────────┤
│ 1   │ 781         │ "Jags"        │ "git://github.com/goedman/Jags.jl.git" │

Genie.Package
+======+======================================+
|  key |                                value |
+======+======================================+
|   id |                        Nullable(781) |
+------+--------------------------------------+
| name |                                 Jags |
+------+--------------------------------------+
|  url | git://github.com/goedman/Jags.jl.git |
+------+--------------------------------------+

julia> SearchLight.relationship(p, :Repo, :has_one)
Nullable(
Model.SQLRelation
+============+=====================================+
|        key |                               value |
+============+=====================================+
|  condition | Nullable{Array{Model.SQLWhere,1}}() |
+------------+-------------------------------------+
|       data |     Nullable{Model.AbstractModel}() |
+------------+-------------------------------------+
|  eagerness |                                lazy |
+------------+-------------------------------------+
| model_name |                                Repo |
+------------+-------------------------------------+
|   required |                               false |
+------------+-------------------------------------+
)

julia> SearchLight.relationship_data!(p, :Repo, :has_one)

31-May 19:46:47:INFO:console_logger:
SQL QUERY: SELECT "repos"."id" AS "repos_id", "repos"."package_id" AS "repos_package_id", "repos"."fullname" AS "repos_fullname", "repos"."readme" AS "repos_readme", "repos"."participation" AS "repos_participation", "repos"."updated_at" AS "repos_updated_at" FROM "repos" WHERE TRUE AND ( "package_id" = ( 781 ) ) LIMIT 1

  0.033548 seconds (1.09 k allocations: 43.352 KB)

Genie.Repo
+===============+================================================================================================+
|           key |                                                                                          value |
+===============+================================================================================================+
|      fullname |                                                                                goedman/Jags.jl |
+---------------+------------------------------------------------------------------------------------------------+
|            id |                                                                                  Nullable(554) |
+---------------+------------------------------------------------------------------------------------------------+
|    package_id |                                                                                  Nullable(781) |
+---------------+------------------------------------------------------------------------------------------------+
| participation |                                                  [0,0,0,0,0,0,0,0,0,0  …  0,0,0,0,0,0,0,0,0,0] |
+---------------+------------------------------------------------------------------------------------------------+
|               |                                                                                         # Jags |
|               |                                                                                                |
|               |                                                                                                |
|        readme | [![Jags](http://pkg.julialang.org/badges/Jags_0.3.svg)](http://pkg.julialang.org/?pkg=Jags&... |
+---------------+------------------------------------------------------------------------------------------------+
|    updated_at |                                                                  Nullable(2016-05-13T12:32:46) |
+---------------+------------------------------------------------------------------------------------------------+
```

### Hydration / dehydration hooks
Julia, being a strongly typed language, upon data retrieval and model type instantiation, the model's properties must be set using the correct types. Genie delegates this task to Julia, so the standard `convert` methods will be used when available. 

However, for more complex logic or specific data structures, you can define specialized persistance and retrieval methods that will be automatically called by the `on_dehydration` and `on_hydration` hooks. If defined, these methods will be used by Genie to convert the data to and from the database.

These functions take as their arguments a tuple of the following type: `(repo::Genie.Repo, field::Symbol, value::Any)`

```julia
type Repo <: AbstractModel
  [ ... code omitted ... ]
  on_dehydration::Nullable{Function}
  on_hydration::Nullable{Function}

  Repo(; 
        [ ... code omitted ... ]
        on_dehydration = Repos.dehydrate, 
        on_hydration = Repos.hydrate
      ) = new("repos", "id", github, id, package_id, fullname, readme, participation, updated_at, belongs_to, on_dehydration, on_hydration)
end

module Repos
using Genie

function dehydrate(repo::Genie.Repo, field::Symbol, value::Any)
  return  if field == :participation 
            join(value, ",")
          elseif field == :updated_at
            value = Dates.now()
          else
            value
          end
end

function hydrate(repo::Genie.Repo, field::Symbol, value::Any)
  return  if field == :participation 
            map(x -> parse(x), split(value, ",")) 
          elseif field == :updated_at
            value = DateParser.parse(DateTime, value)
          else
            value
          end
end
end
```

### Validations
...

### Authorization
...

## Views
Genie's goal for v1.0 is to be a strong alternative for building RESTful APIs and for serving SPA backends. It tries to make it simpler to build complex JSON views by providing a straightforward but powerful and flexible JSON builder. 

Support for rendering HTML views is provided via the `Mustache.jl` package. This is designed mostly to assist with serving simple UIs, like for example the ones that are part of the OAuth process. 

If necessary, asset management should be provided by the JavaScript framework employed by the SPA or by a stand-alone JavaScript build tool, such as Brunch (http://brunch.io) or Grunt (http://gruntjs.com). 

The views rendering functionality is provided by the `Renderer` module. 

```julia
p = SearchLight.find_one_by(Package, :id, 42) |> Base.get
Render.respond(Render.json(:packages, :show, package = p))
```

##### app/resources/packages/views/show.jl

```julia
JSONAPI.builder(
  data = JSONAPI.elem(
    package, 
    type_         = "package", 
    id            = ()-> package.id |> Util.expand_nullable, 
    attributes    = JSONAPI.elem(
      package, 
      name          = ()-> package.name, 
      url           = ()-> package.url, 
      readme        = ()-> Model.relationship_data!(package, :Repo, :has_one).readme, 
      participation = ()-> Model.relationship_data!(package, :Repo, :has_one).participation 
    ), 
    links = JSONAPI.elem(
      package, 
      self = ()-> "/api/v1/packages/$(package.id |> Util.expand_nullable)"
    )
  )
)
```

responding with the following JSONAPI.org structured JSON object: 

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
/* output omitted */
         The documentation for the development version of this package is \n[here](https://tshort.github.io/Maker.jl/latest/).\n\n",
         "name":"Maker",
         "participation":[
            0,
            0,
/* output omitted */
            0,
            0
         ],
         "url":"git://github.com/tshort/Maker.jl.git"
      }
   }
}
```

## Controllers
Controllers in Genie are just plain Julia modules. Their role is to orchestrate the exchange of data between models and the views. 

The controllers can be nested as needed, in order to define logical hierarchies. 

Controller methods must take as argument the following tuple, `(p::Genie.GenieController, params::Dict{Symbol, Any}, req::Request, res::Response)`. `p::Genie.GenieController` is an instance of the designated controller (mainly used for dispatch), `params::Dict{Symbol, Any}` contains any parameters (`GET`, `POST`, etc) sent with the request, while the `req::Request` and `res::Response` are the raw HttpServer Request and Response objects. 

```julia
module API 
module V1

using Genie
using Model

function show(p::Genie.GenieController, params::Dict{Symbol, Any}, req::Request, res::Response)
  package = SearchLight.find_one(Package, params[:package_id])
  if ! isnull(package) 
    package = Base.get(package)
    Render.respond(Render.json(:packages, :show, package = package))
  else 
    Render.respond(Render.JSONAPI.error(404))  
  end
end

end
```

## Router
Genie's router is pretty unsurprising, acting as the proxy between request URLs and controller methods. Once a route is matched, the router includes the corresponding controller file and invokes the designated method, passing as arguments the expected tuple (see above, "Controllers") `(p::Genie.GenieController, params::Dict{Symbol, Any}, req::Request, res::Response)`

A very simple `routes.jl` file can look like: 

```julia
using Router

route(GET, "/api/v1/packages/search", "packages#API.V1.search", with = Dict{Symbol, Any}(:is_api => true))
route(GET, "/api/v1/packages/:package_id", "packages#API.V1.show", with = Dict{Symbol, Any}(:is_api => true))
```

See how you can "dot into" the module hierarchy to define for example API versioning.

## Channels
...

## App server
Genie uses `HttpServer.jl` as its internatal web/app server. The methods for starting the app server are available in the `AppServer` module. 

```julia
julia> AppServer.spawn(8002)
Listening on 0.0.0.0:8002...
Nullable(RemoteRef{Channel{Any}}(1,1,1))
```

The result of the `spawn` function is stored in the `Genie.genie_app.server` in case it's needed later for retrieval and manipulation.

A Genie application can be started in "server mode" using: 
```
$ ./genie s
```

## Configuration
... 

## Database versioning / migrations
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

## Package versioning
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