![Genie Logo](https://dl.dropboxusercontent.com/s/0dbiza50r63cvvc/genie_logo.png)

# Genie
### High-performance high-productivity Julia web framework. 

Genie is a full-stack MVC web framework that provides a streamlined and efficient workflow for developing modern web applications. It builds on top of Julia's (julialang.org) strengths (high-level, high-performance, dynamic, JIT compiled, functional programming language), adding a series of modules, methods and tools for promoting productive web development. 

In order to start a Genie interactive session through the Julia REPL, just type: 
```
$> julia -L genie.jl --color=yes -q
```

### v0.5
Genie has recently reached verson 0.5 which means it's somewhere in the middle of it's first release cycle. It is still very much work in progress and be warned, things might change often before reaching v1.0. 

If you want to develop your web application with Genie, that is entirely doable, provided that you're willing to dive into the source code and contribute (you're my hero! ❤️). Genie already includes most of the features necessary for developing professional grade web applications, backends, APIs and server side scripts. 

But at the moment it also lacks some critical features, which will be added in the upcoming minor versions. Most notably, handling of `POST`ed data, model validations and `has_many`, `has_many_through` and `has_one_through` model relationships. 

If you prefer to wait until it reaches a more stable version, you can stay up to date with the progress by starring and watching the Github repo. 

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

### Database configuration
Genie uses the YAML (http://yaml.org) format to store database connection settings. YAML is a simple, clean and humanly readable and editable format, with strict validation rules and widespread editor support. 

##### config/database.yaml

```yaml
dev:
  adapter: PostgreSQL
  database: pkg_info_dev
  host: localhost
  username: genie
  password: some_pass_here
  port: 5432

prod:
  adapter: PostgreSQL
  database: pkg_info_prod
  host: localhost
  username: genie
  password: some_pass_here
  port: 5432

test:
  adapter: PostgreSQL
  database: pkg_info_test
  host: localhost
  username: genie
  password: some_pass_here
  port: 5432
```

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

##### app/resources/packages/model.jl

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

##### app/resources/repos/model.jl

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

##### app/resources/repos/model.jl

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
[TODO]

### Authorization
[TODO]

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

##### http://localhost:8000/api/v1/packages/42

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

Using the `JSONAPI.builder()` is not a requirement - `Render.json()` accepts a Dictionary as it's argument, so your views can simply return that. 

## Controllers
Controllers in Genie are just plain Julia modules. Their role is to orchestrate the exchange of data between models and the views. 

The controllers can be nested as needed, in order to define logical hierarchies. 

Controller methods must take as argument the following tuple, `(p::Genie.GenieController, params::Dict{Symbol, Any}, req::Request, res::Response)`. `p::Genie.GenieController` is an instance of the designated controller, `params::Dict{Symbol, Any}` contains any parameters (`GET`, `POST`, etc) sent with the request, while the `req::Request` and `res::Response` are the raw HttpServer Request and Response objects. 

##### app/resources/packages/controller.jl

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

##### config/routes.jl

```julia
using Router

route(GET, "/api/v1/packages/search", "packages#API.V1.search", with = Dict{Symbol, Any}(:is_api => true))
route(GET, "/api/v1/packages/:package_id", "packages#API.V1.show", with = Dict{Symbol, Any}(:is_api => true))
```

See how you can "dot into" the module hierarchy to define, for example, API versioning.

Additional parameters can be packeged with the route's definition, in the `with` dictionary - they will be passed over to the controller as part of the `params` dict. 

The `route()` function will soon accept additional arguments for matching based on additional filters, such as host, subdomain or protocol. 

## Web channels (over websockets)
[TODO]

## App server
Genie uses `HttpServer.jl` as its internal web/app server. The methods for starting the app server (`start()` and `spawn()` are available in the `AppServer` module. 

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
Genie apps run off a main configuration file which controls many aspects of their behavior. The core comes with its own configuration settings which contains sensible defaults - however, these can and should be tweaked depending on the needs of your app and how you're running it (especially in regards to development vs production mode). 

The various defaults and utility functions are exposed by the `Configuration` module. 

### Environments
The concept of environments is deeply rooted in Genie. This allows setting and using optimized configurations depending on whether the app is during development (with emphasis on verbose logging), test, or production (with emphasis on speed). 

Per enviroment configuration files can be found in `config/env/`. This is an example of a production configuration, disabling most logging. 

##### config/env/prod.jl

```julia
using Configuration
const config = Config(output_length = 100, 
                      supress_output = true, 
                      log_db = false, 
                      log_requests = false, 
                      log_responses = false)

export config
```

#### Setting the active environment
In order to set the active environment (or change it from the default `dev`) you can pass the `GENIE_ENV` argument in the shell, when starting your Genie app. 

```
$> GENIE_ENV=prod julia -L genie.jl --color=yes -q

 _____         _
|   __|___ ___|_|___
|  |  | -_|   | | -_|
|_____|___|_|_|_|___|


Starting Genie in >> PROD << mode
```

> Genie will promptly indicate the active environment. 

Or: 

```
$> GENIE_ENV=prod ./genie.jl s -p 8001

 _____         _
|   __|___ ___|_|___
|  |  | -_|   | | -_|
|_____|___|_|_|_|___|


Starting Genie in >> PROD << mode
```

#### The main `env.jl` file
Sometimes it's impractical to pass additional parameters to the `genie.jl` startup script, for example in `hashbang` files on different platforms. 

In this case you can provide an `env.jl` file in the root of the app. This is loaded very early in the app's startup process and allows setting up any number of environment variables. However, here you can't configure any app settings, as these are not loaded at this time. For this, use the dedicated configuration files for the corresponding environment. 

##### env.jl
```julia
# if the environment is not defined, use this
if ! haskey(ENV, "GENIE_ENV") 
  ENV["GENIE_ENV"] = "prod"
end
```

### Initializers
If your application needs certain configurations to be setup or say some of your libraries require dedicated settings to be available before using them, you can drop such config files into the `/config/initializers` folder. These will be automatically included by Genie before the models, controllers or the views will be invoked. 

##### config/initializers/github_auth.jl

```julia
using GitHub
const GITHUB_AUTH = GitHub.authenticate(GITHUB_AUTH_KEY)
```
> Initializer file for `GitHub.jl`

### Secrets
Sensitive information should be placed in the `config/secrets.jl` file. This file is automatically loaded by Genie before the models, views or the controller are invoked - and is already added to the app's `.gitignore` file to avoid accidentally publishing it. 

## Logging
Logging is a central part in Genie's architecture, one of its key components. One can hardly find of a more time consuming and daunting task than debugging your backend code without proper logging - and a lot of effort has been put into getting this right. 

Genie uses `Logging.jl` for it's logging needs, and exposes this functionality through the `Genie.log()` function. 

By default, in `development` mode, Genie is **very** verbose. It will log SQL sent to the database, the `DataFrame`s representing the SQL results, `@time` measurments of the queries, server requests and responses, etc. The level of logging can be controlled via the main config file (see above). 

Out of the box, Genie comes with a console and a file logger. The console logger outputs everything in the terminal where the Genie app is running; while the file logger writes to the dedicated log file corresponding to the active environment. 

The log files are found, unsurprisingly, in the `log/` folder. 

```
julia> p = SearchLight.rand(Package)

01-Jun 22:11:28:INFO:console_logger:
SQL QUERY: SELECT "packages"."id" AS "packages_id", "packages"."name" AS "packages_name", "packages"."url" AS "packages_url" FROM "packages" ORDER BY random() ASC LIMIT 1

  0.034524 seconds (1.09 k allocations: 43.570 KB)

01-Jun 22:11:29:INFO:console_logger:
1×3 DataFrames.DataFrame
│ Row │ packages_id │ packages_name │ packages_url                            │
├─────┼─────────────┼───────────────┼─────────────────────────────────────────┤
│ 1   │ 1067        │ "Kalman.jl"   │ "git://github.com/wkearn/Kalman.jl.git" │

1-element Array{Genie.Package,1}:

Genie.Package
+======+=======================================+
|  key |                                 value |
+======+=======================================+
|   id |                        Nullable(1067) |
+------+---------------------------------------+
| name |                             Kalman.jl |
+------+---------------------------------------+
|  url | git://github.com/wkearn/Kalman.jl.git |
+------+---------------------------------------+


julia> Genie.log(p)

01-Jun 22:11:44:INFO:console_logger:
[
Genie.Package
+======+=======================================+
|  key |                                 value |
+======+=======================================+
|   id |                        Nullable(1067) |
+------+---------------------------------------+
| name |                             Kalman.jl |
+------+---------------------------------------+
|  url | git://github.com/wkearn/Kalman.jl.git |
+------+---------------------------------------+
]
```

> Example of logging during a Genie REPL session. Genie types know how to display themself in a readable format. 

```
01-Jun 08:13:07:INFO:console_logger:
Response(200 OK, 1 headers, 1442 bytes in body)
+==========+=========================================================================================================+
|      key |                                                                                                   value |
+==========+=========================================================================================================+
|  cookies |                                                                                                    +==+ |
+----------+---------------------------------------------------------------------------------------------------------+
|     data | {"data":{"type":"package","id":42,"links":{"self":"/api/v1/packages/42"},"attributes":{"readme":"# M... |
+----------+---------------------------------------------------------------------------------------------------------+
| finished |                                                                                                   false |
+----------+---------------------------------------------------------------------------------------------------------+
|          |                                                                            +==============+===========+ |
|          |                                                                            |          key |     value | |
|          |                                                                            +==============+===========+ |
|          |                                                                            | Content-Type | text/json | |
|  headers |                                                                            +--------------+-----------+ |
+----------+---------------------------------------------------------------------------------------------------------+
|  history |                                                                                   HttpCommon.Response[] |
+----------+---------------------------------------------------------------------------------------------------------+
|  request |                                                                          Nullable{HttpCommon.Request}() |
+----------+---------------------------------------------------------------------------------------------------------+
| requests |                                                                                    HttpCommon.Request[] |
+----------+---------------------------------------------------------------------------------------------------------+
|   status |                                                                                                     200 |
+----------+---------------------------------------------------------------------------------------------------------+
```

> Response object logged. 

Additional loggers can be added at any point in the app (for example by using an initializer). Then, you can either `push!` your logger to `Genie.config.loggers` to be hooked into Genie's logging mechanism and have all logging data sent to your logger too; or you can directly send data to your logger wherever you see fit. 

#### `@psst`
Genie also provides the `@psst` macro which takes an expression as its argument and executes it while disabling all logging. 

```julia
julia> p = @psst SearchLight.rand(Package)
1-element Array{Genie.Package,1}:

Genie.Package
+======+=======================================+
|  key |                                 value |
+======+=======================================+
|   id |                         Nullable(483) |
+------+---------------------------------------+
| name |                                 Loess |
+------+---------------------------------------+
|  url | git://github.com/dcjones/Loess.jl.git |
+------+---------------------------------------+
```

## Database versioning / migrations
At the moment Genie lacks full migrations support - meaning that it does not yet offer features for database agnostic manipulation of the tables. Instead it uses what can be called *database scripts*, meaning that table manipulation SQL queries need to be written by hand. Full support for migrations is on the roadmap to v1.0. 

Genie provides database versioning functionality, coupled with a migration generator and a migration runner. 

### Database initialization
Genie takes care of setting up its database versioning support. `up` migrations are stored in a table called `schema_migrations` inside your app's database. In order to create this table, you must execute at the command prompt: 

```
$> ./genie.jl db:init

01-Jun 23:02:51:INFO:console_logger:
SQL QUERY: CREATE TABLE schema_migrations (version varchar(30) CONSTRAINT firstkey PRIMARY KEY)

01-Jun 23:02:51:INFO:console_logger:
Created table schema_migrations or table already exists
```

### Migrations status
In order to check what migrations exist and wheter they're `up` or `down`, you need to execute: 

```
$> ./genie.jl migration:status

+===+============================================+
|   |                       Class name & status  |
|   |                                 File name  |
+===+============================================+
|   |                  CreateTablePackages: DOWN |
| 1 | 20160207095411016_create_table_packages.jl |
+---+--------------------------------------------+
|   |                     CreateTableRepos: DOWN |
| 2 |    20160227213638909_create_table_repos.jl |
+---+--------------------------------------------+
```

### Running migrations 
Then you can use the migration runner to execute the desired database script: 

```
./genie.jl --migration:up=CreateTablePackages

02-Jun 08:07:00:INFO:console_logger:
SQL QUERY: CREATE SEQUENCE packages__seq_id

  0.057904 seconds (42.42 k allocations: 1.673 MB)

02-Jun 08:07:00:INFO:console_logger:
SQL QUERY:   CREATE TABLE IF NOT EXISTS packages (
    id            integer CONSTRAINT packages__idx_id PRIMARY KEY DEFAULT NEXTVAL('packages__seq_id'),
    name          varchar(100) NOT NULL,
    url           text NOT NULL,
    updated_at    timestamp DEFAULT current_timestamp,
    CONSTRAINT packages__idx_name UNIQUE(name)
    -- CONSTRAINT packages__idx_url UNIQUE(url)
  )


  0.016703 seconds (3 allocations: 128 bytes)

02-Jun 08:07:00:INFO:console_logger:
SQL QUERY: ALTER SEQUENCE packages__seq_id OWNED BY packages.id;

  0.003619 seconds (3 allocations: 128 bytes)

02-Jun 08:07:00:INFO:console_logger:
Executed migration CreateTablePackages up
```

### Generating migrations
Genie uses certain conventions to seamlessly integrate database versioning through migrations, from file names to types and method names. 

To make it easy, Genie provides a migrations generator. 

```
./genie.jl --migration:new=create_table_users

02-Jun 08:28:48:INFO:console_logger:
New migration created at db/migrations/20160602062848129_create_table_users.jl
```

#### db/migrations/20160602062848129\_create\_table\_users.jl

```julia
using Genie
using Database 

type CreateTableUsers
end 

function up(_::CreateTableUsers)
  error("Not implemented")
end

function down(_::CreateTableUsers)
  error("Not implemented")
end
```

A complete database script for creating and droping a table (with PostgreSQL) can look like: 

##### db/migrations/20160227213638909\_create\_table\_repos.jl

```julia
using Genie
using Database 

type CreateTableRepos
end 

function up(_::CreateTableRepos)
  Database.query("""CREATE SEQUENCE repos__seq_id""")
  Database.query("""
    CREATE TABLE IF NOT EXISTS repos (
      id              integer CONSTRAINT repo__idx_id PRIMARY KEY DEFAULT NEXTVAL('repos__seq_id'), 
      package_id      integer, 
      fullname        varchar(100) NOT NULL, 
      readme          text,
      participation   text,
      updated_at      timestamp DEFAULT current_timestamp, 
      CONSTRAINT repo__idx_fullname UNIQUE(fullname), 
      CONSTRAINT repo__idx_package_id UNIQUE(package_id)
    )
  """)
  Database.query("""ALTER SEQUENCE repos__seq_id OWNED BY repos.id;""")
  Database.query("""CREATE INDEX repo__idx_readme ON repos USING gin(to_tsvector('english', readme))""")
end

function down(_::CreateTableRepos)
  Database.query("DROP TABLE repos")
end
```

Execute `./genie -h` to get a list with all the available options. 

### Migrations interface
All migration scripts must define: 

* a type, which must be named corresponding to the migration script. Ex: `type FooBarBaz` would correspond to a `*_foo_bar_baz.jl` migration. 
* the method `up(_::FooBarBaz)` that will be invoked by Genie when migrating `up`
* the method `down(_::FooBarBaz)` that will be invoked by Genie when migrating `down`

## Test runner
Genie comes with an integrated test runner based on `FactCheck`. When executed with `./genie.jl test:run` it will automatically run all the files included in the `test/` folder that are named `*_test.jl`. The test files can be grouped inside nested folders within `test/`, they will all be picked. 

The location of the test folder is defined in the main config file, and can be overwritten within active env's configuration file. 

Within the `test/` folder you can find `test_config.jl` which is used by the test runner. This is loaded before any tests are run and can be used for bootstrapping up your tests. 

The testing functionality is included in the `Tester` module and amongst other things, it provides a `reset_db()` function which wipes and rebuilds the test database. Be sure not to accidentaly invoke this function in the dev or prod environments!

```julia
using Faker
using Model

function setup()
  Tester.reset_db()

  for i in 1:10 
    p = Package()
    p.name = Faker.word() * "_" * Faker.word() * "_" * Faker.word()
    p.url = Faker.uri() * "?" * string(hash(randn()))

    Model.save!(p)
  end
end

function teardown()
  Model.delete_all(Package)
end

facts("Model basics") do
  @psst setup()

  context("Model::all should find 10 packages in the DB") do
      all_packages = @psst Model.all(Package)
      @fact length(all_packages) --> 10
  end

  context("Model::find without args should find 10 packages in the DB") do
      all_packages = @psst Model.find(Package)
      @fact length(all_packages) --> 10
  end

  context("Model::find with limit 5 should find 5 packages in the DB") do
      all_packages = @psst Model.find(Package, SQLQuery(limit = SQLLimit(5)))
      @fact length(all_packages) --> 5
  end

  context("Model::find with limit 5 and order DESC by id should find 5 packages in the DB and sort correctly") do
      all_packages = @psst Model.find(Package, SQLQuery(limit = SQLLimit(5), order = [SQLOrder(:id, "DESC")]))
      @fact [10, 9, 8, 7, 6] --> map(x -> Base.get(x.id), all_packages)
  end

  context("Model::rand_one should return a not null nullable model") do 
    package = @psst Model.rand_one(Package)
    @fact typeof(package) --> Nullable{AbstractModel}
    @fact isnull(package) --> false
  end

  context("Model::find_one should return a not null nullable package with the same id") do 
    package = @psst Model.find_one(Package, 1)
    @fact Base.get(package).id |> Base.get --> 1
  end

  context("Complex finds") do 
    @pending Model.find() --> :?
  end

  context("Find rand") do 
    @pending Model.rand() --> :?
  end

  context("Find one") do 
    @pending Model.find_one() --> :?
  end

  @psst teardown()
end
```

> Some tests for Genie.Model 

## Task runner
Genie comes bundled with a task runner which makes it very easy to write and execute server side scripts, with access to all of Genie's ecosystem. An obvious use case for these are recurring maintainance tasks started by a cron job. 

These `task`s are scripts that can be executed by your Genie app, and have nothing to do with Julia's `Task`s. 

### Creating new Genie tasks
Similar to the database migration scripts, the tasks must follow certain conventions in regards to naming, location, implemented methods, etc. 

To make it harder to get this wrong, Genie provides a generator. 

```
$> ./genie.jl --task:new=foo_bar

02-Jun 11:35:00:INFO:console_logger:
New task created at task/foo_bar_task.jl
```

##### task/foo\_bar\_task.jl

```julia
using Genie

type FooBarTask
end

function description(_::FooBarTask)
  """
  Description of the task here
  """
end

function run_task!(_::FooBarTask, parsed_args = Dict{AbstractString, Any}())
  # Build something great
end
```

> The empty task file generated by Genie

A very simple task that lints all the files in a given folder can look like this: 

```julia
using Genie
using Lint

type LintFilesTask
end

function description(_::LintFilesTask)
  """
  Lints the files in the indicated dir
  """
end

function run_task!(_::LintFilesTask, parsed_args = Dict())
  dir = joinpath("lib", "Genie", "src")
  for filename in Task(() -> walk_dir(dir))
    lintfile(filename)
  end
end
```

### The task runner interface
All tasks scripts must define: 

* a type, which must be named corresponding to the task script. Ex: `type FooBarBaz` would correspond to a `foo_bar_baz.jl` task file. 
* the method `description(_::FooBarBaz)` which is used by Genie when listing all available tasks. This should return a string with the human readable description of what the task does. 
* the method `run_task!(_::FooBarBaz, parsed_args = Dict())` which will be invoked by Genie to actually execute the task - and where you should place your logic. The `parsed_args` Dict will receive all the command line arguments passed upon the invocation of the task. 

### Listing available tasks
Genie will promply display all the available tasks if you execute `./genie task:list`.

```
$> ./genie.jl task:list

+===+====================================================================================================+
|   |                                                                                         Task name  |
|   |                                                                                          Filename  |
|   |                                                                                       Description  |
+===+====================================================================================================+
|   |                                                                                      LintFilesTask |
|   |                                                                                 lint_files_task.jl |
| 1 |                                                              Lints the files in the indicated dir  |
+---+----------------------------------------------------------------------------------------------------+
|   |                                                                                 PackagesImportTask |
|   |                                                                            packages_import_task.jl |
| 2 |                             Imports list of packages (name, URL) in database, using MetadataTools  |
+---+----------------------------------------------------------------------------------------------------+
|   |                                                                           PackagesSearchImportTask |
|   |                                                                     packages_search_import_task.jl |
| 3 |                                     Searches Github for Julia packages and imports them in the DB  |
+---+----------------------------------------------------------------------------------------------------+
|   |                                                                                    ReposImportTask |
|   |                                                                               repos_import_task.jl |
| 4 | Imports list of repos (name, URL) in database, using local package information and the GitHub pkg  |
+---+----------------------------------------------------------------------------------------------------+
```

### Running tasks
In order to run any of the tasks, execute `./genie --task:run=FooBarBazTask

```
$> ./genie.jl --task:run=LintFilesTask

lib/Genie/src/Migration.jl:100 I372 abspath(joinpath(Genie.config.db_migrations_folder,migration.migration_file_name)): unable to follow non-literal include file
lib/Genie/src/Model.jl:43 E321 to_nullable: use of undeclared symbol
lib/Genie/src/Model.jl:82 E521 query_result_df: apparent type DataFrames.DataFrame is not a container type
lib/Genie/src/Model.jl:350 E321 escape_column_name: use of undeclared symbol
lib/Genie/src/Model.jl:350 E321 strip_module_name: use of undeclared symbol

[ ... output omitted ... ]
```

## Caching
[TODO]

## Package versioning
When running applications in production, it's critical that a `Pkg.update()` does not inadvertently breaks your code by bringing backwards incompatible changes to some of the packages you're using. 

It's recommended that you use `DeclarativePackages.jl` to manage and version your app's dependencies (https://github.com/rened/DeclarativePackages.jl). 

## Hosting in production
### Monitoring and restarting Genie apps with Supervisor
[DONE - To write]
### Serving Genie apps with Nginx 
[DONE - To write]
### Parallel execution of Genie apps with Nginx load balancing
[TODO]
### Nginx response caching
[DONE - To write]

##Roadmap (TODOs)
- [ ] handling of POST data and routes
- [ ] model validation
- [ ] controller authorization
- [ ] more generators: new app, resources, models, controllers, etc. 
- [ ] web channels
- [ ] caching
- [ ] database agnostic migrations
- [ ] resourceful routes
- [ ] proper API documentation
- [ ] admin

## Acknowledgements
* The amazing Genie logo was designed by my friend Alvaro (www.yeahstyledg.com). You rock! 
* Genie uses a multitude of packages that have been contributed by so many incredible developers. 
* I wouldn't have made it so far without the help and the patience of the amazing people at the `julia-users` group. 

Thank you all.