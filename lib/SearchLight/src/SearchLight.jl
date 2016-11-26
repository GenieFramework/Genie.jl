module SearchLight

using Genie

include("model_types.jl")

using Database, DataFrames, DataStructures, DateParser, Util, Reexport, Configuration, Logger

@reexport using Validation

export RELATIONSHIP_HAS_ONE, RELATIONSHIP_BELONGS_TO, RELATIONSHIP_HAS_MANY
export disposable_instance, to_fully_qualified_sql_column_names, persistable_fields, escape_column_name, is_fully_qualified, to_fully_qualified
export relationships, has_relationship, find_df, is_persisted, prepare_for_db_save

const RELATIONSHIP_HAS_ONE = :has_one
const RELATIONSHIP_BELONGS_TO = :belongs_to
const RELATIONSHIP_HAS_MANY = :has_many

# internals

direct_relationships() = [RELATIONSHIP_HAS_ONE, RELATIONSHIP_BELONGS_TO, RELATIONSHIP_HAS_MANY]


#
# ORM methods
#


"""
    find_df{T<:AbstractModel, N<:AbstractModel}(m::Type{T}[, q::SQLQuery[, j::Vector{SQLJoin{N}}]])::DataFrames.DataFrame

Executes a SQL `SELECT` query against the database and returns the resultset as a `DataFrame`.

# Examples
```julia
julia> SearchLight.find_df(Article);

2016-11-15T23:16:19.152 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\"

0.003031 seconds (16 allocations: 576 bytes)

32×7 DataFrames.DataFrame
│ Row │ articles_id │ articles_title                                     │ articles_summary                                                                                                                │
├─────┼─────────────┼────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1   │ 4           │ "Possimus sit cum nesciunt doloribus dignissimos." │ "Similique.\nUt debitis qui perferendis.\nVoluptatem qui recusandae ut itaque voluptas.\nSunt."                                       │
│ 2   │ 5           │ "Voluptas ea incidunt et provident."               │ "Animi ducimus in.\nVoluptatem ipsum doloribus perspiciatis consequatur a.\nVel quibusdam quas veritatis laboriosam.\nEum quibusdam." │
...

julia> SearchLight.find_df(Article, SQLQuery(limit = 5))

2016-11-15T23:12:10.513 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" LIMIT 5

0.000846 seconds (16 allocations: 576 bytes)

5×7 DataFrames.DataFrame
│ Row │ articles_id │ articles_title                                     │ articles_summary                                                                                                                │
├─────┼─────────────┼────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1   │ 4           │ "Possimus sit cum nesciunt doloribus dignissimos." │ "Similique.\nUt debitis qui perferendis.\nVoluptatem qui recusandae ut itaque voluptas.\nSunt."                                       │
│ 2   │ 5           │ "Voluptas ea incidunt et provident."               │ "Animi ducimus in.\nVoluptatem ipsum doloribus perspiciatis consequatur a.\nVel quibusdam quas veritatis laboriosam.\nEum quibusdam." │
...
```
"""
function find_df{T<:AbstractModel, N<:AbstractModel}(m::Type{T}, q::SQLQuery, j::Vector{SQLJoin{N}}) :: DataFrames.DataFrame
  query(to_fetch_sql(m, q, j)) :: DataFrames.DataFrame
end
function find_df{T<:AbstractModel}(m::Type{T}, q::SQLQuery) :: DataFrames.DataFrame
  query(to_fetch_sql(m, q)) :: DataFrames.DataFrame
end
function find_df{T<:AbstractModel}(m::Type{T}) :: DataFrames.DataFrame
  find_df(m, SQLQuery())
end


"""
    find{T<:AbstractModel, N<:AbstractModel}(m::Type{T}[, q::SQLQuery[, j::Vector{SQLJoin{N}}]])

Executes a SQL `SELECT` query against the database and returns the resultset as a `Vector{T<:AbstractModel}`.

# Examples:
```julia
julia> SearchLight.find(Article, SQLQuery(where = [SQLWhereExpression("id BETWEEN ? AND ?", [10, 20])], offset = 5, limit = 5, order = :title))

2016-11-25T22:38:24.003 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE TRUE AND id BETWEEN 10 AND 20 ORDER BY articles.title ASC LIMIT 5 OFFSET 5

0.001486 seconds (16 allocations: 576 bytes)

5-element Array{App.Article,1}:
...

julia> SearchLight.find(Article)

2016-11-25T22:40:56.083 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\"

0.011748 seconds (16 allocations: 576 bytes)

38-element Array{App.Article,1}:
...
```
"""
function find{T<:AbstractModel, N<:AbstractModel}(m::Type{T}, q::SQLQuery, j::Vector{SQLJoin{N}}) :: Vector{T}
  to_models(m, find_df(m, q, j))
end
function find{T<:AbstractModel}(m::Type{T}, q::SQLQuery) :: Vector{T}
  to_models(m, find_df(m, q))
end
function find{T<:AbstractModel}(m::Type{T}) :: Vector{T}
  find(m, SQLQuery())
end


"""
    find_by{T<:AbstractModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput) :: Vector{T}
    find_by{T<:AbstractModel}(m::Type{T}, column_name::Any, value::Any) :: Vector{T}
    find_by{T<:AbstractModel}(m::Type{T}, sql_expression::SQLWhereExpression) :: Vector{T}

Executes a SQL `SELECT` query against the database, applying a `WHERE` filter using the `column_name` and the `value`.
Returns the resultset as a `Vector{T<:AbstractModel}`.

# Examples:
```julia
julia> SearchLight.find_by(Article, :slug, "cupiditate-velit-repellat-dolorem-nobis")

2016-11-25T22:45:19.157 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE TRUE AND (\"slug\" = 'cupiditate-velit-repellat-dolorem-nobis')

0.000802 seconds (16 allocations: 576 bytes)

1-element Array{App.Article,1}:

App.Article
+==============+=========================================================+
|          key |                                                   value |
+==============+=========================================================+
|           id |                                     Nullable{Int32}(36) |
+--------------+---------------------------------------------------------+
...
+--------------+---------------------------------------------------------+
|         slug |                 cupiditate-velit-repellat-dolorem-nobis |
+--------------+---------------------------------------------------------+

julia> SearchLight.find_by(Article, SQLWhereExpression("slug LIKE ?", "%dolorem%"))

2016-11-25T23:15:52.5730000000000001 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE TRUE AND slug LIKE '%dolorem%'

0.000782 seconds (16 allocations: 576 bytes)

1-element Array{App.Article,1}:

App.Article
+==============+=========================================================+
|          key |                                                   value |
+==============+=========================================================+
|           id |                                     Nullable{Int32}(36) |
+--------------+---------------------------------------------------------+
...
+--------------+---------------------------------------------------------+
|         slug |                 cupiditate-velit-repellat-dolorem-nobis |
+--------------+---------------------------------------------------------+
```
"""
function find_by{T<:AbstractModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput) :: Vector{T}
  find(m, SQLQuery(where = [SQLWhere(column_name, value)]))
end
function find_by{T<:AbstractModel}(m::Type{T}, column_name::Any, value::Any) :: Vector{T}
  find_by(m, SQLColumn(column_name), SQLInput(value))
end
function find_by{T<:AbstractModel}(m::Type{T}, sql_expression::SQLWhereExpression) :: Vector{T}
  find(m, SQLQuery(where = [sql_expression]))
end


"""
    find_one_by{T<:AbstractModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput; order = SQLOrder(m()._id)) :: Nullable{T}
    find_one_by{T<:AbstractModel}(m::Type{T}, column_name::Any, value::Any; order = SQLOrder(m()._id)) :: Nullable{T}
    find_one_by{T<:AbstractModel}(m::Type{T}, sql_expression::SQLWhereExpression; order = SQLOrder(m()._id)) :: Nullable{T}

Executes a SQL `SELECT` query against the database, applying a `WHERE` filter using the `column_name` and the `value`
or the `sql_expression`.
Returns the first result as a `Nullable{T<:AbstractModel}`.

# Examples:
```julia
julia> SearchLight.find_one_by(Article, :title, "Cupiditate velit repellat dolorem nobis.")

2016-11-25T23:43:13.969 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE (\"title\" = 'Cupiditate velit repellat dolorem nobis.')

0.002319 seconds (1.23 k allocations: 52.688 KB)

Nullable{App.Article}(
App.Article
+==============+=========================================================+
|          key |                                                   value |
+==============+=========================================================+
|           id |                                     Nullable{Int32}(36) |
+--------------+---------------------------------------------------------+
...
+--------------+---------------------------------------------------------+
|        title |                Cupiditate velit repellat dolorem nobis. |
+--------------+---------------------------------------------------------+

julia> SearchLight.find_one_by(Article, SQLWhereExpression("slug LIKE ?", "%nobis"))

2016-11-25T23:51:40.934 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE slug LIKE '%nobis'

0.001152 seconds (16 allocations: 576 bytes)

Nullable{App.Article}(
App.Article
+==============+=========================================================+
|          key |                                                   value |
+==============+=========================================================+
|           id |                                     Nullable{Int32}(36) |
+--------------+---------------------------------------------------------+
...
+--------------+---------------------------------------------------------+
|         slug |                 cupiditate-velit-repellat-dolorem-nobis |
+--------------+---------------------------------------------------------+
)

julia> SearchLight.find_one_by(Article, SQLWhereExpression("title LIKE ?", "%u%"), order = SQLOrder(:updated_at, :desc))

2016-11-26T23:00:15.638 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE title LIKE '%u%' ORDER BY articles.updated_at DESC LIMIT 1

0.000891 seconds (16 allocations: 576 bytes)

Nullable{App.Article}(
App.Article
+==============+================================================================================+
|          key |                                                                          value |
+==============+================================================================================+
|           id |                                                            Nullable{Int32}(19) |
+--------------+--------------------------------------------------------------------------------+
...
)

julia> SearchLight.find_one_by(Article, :title, "Id soluta officia quis quis incidunt.", order = SQLOrder(:updated_at, :desc))

2016-11-26T23:03:12.311 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE (\"title\" = 'Id soluta officia quis quis incidunt.') ORDER BY articles.updated_at DESC LIMIT 1

0.003903 seconds (1.23 k allocations: 52.688 KB)

Nullable{App.Article}(
App.Article
+==============+================================================================================+
|          key |                                                                          value |
+==============+================================================================================+
|           id |                                                            Nullable{Int32}(19) |
+--------------+--------------------------------------------------------------------------------+
...
)
```
"""
function find_one_by{T<:AbstractModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput; order = SQLOrder(m()._id)) :: Nullable{T}
  find(m, SQLQuery(where = [SQLWhere(column_name, value)], order = order, limit = 1)) |> to_nullable
end
function find_one_by{T<:AbstractModel}(m::Type{T}, column_name::Any, value::Any; order = SQLOrder(m()._id)) :: Nullable{T}
  find_one_by(m, SQLColumn(column_name), SQLInput(value), order = order)
end
function find_one_by{T<:AbstractModel}(m::Type{T}, sql_expression::SQLWhereExpression; order = SQLOrder(m()._id)) :: Nullable{T}
  find(m, SQLQuery(where = [sql_expression], order = order, limit = 1)) |> to_nullable
end


"""
    find_one_by!!{T<:AbstractModel}(m::Type{T}, column_name::Any, value::Any) :: T
    find_one_by!!{T<:AbstractModel}(m::Type{T}, sql_expression::SQLWhereExpression) :: T

Similar to `find_one_by` but also attempts to `get` the value inside the `Nullable` by means of `Base.get`.
Returns the value if is not `NULL`. Throws a `NullException` otherwise.

# Examples:
```julia
julia> SearchLight.find_one_by!!(Article, :id, 1)

2016-11-26T22:20:32.788 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE (\"id\" = 1) ORDER BY articles.id ASC LIMIT 1

0.001170 seconds (16 allocations: 576 bytes)

App.Article
+==============+===============================================================================+
|          key |                                                                         value |
+==============+===============================================================================+
|           id |                                                            Nullable{Int32}(1) |
+--------------+-------------------------------------------------------------------------------+
...

julia> SearchLight.find_one_by!!(Article, SQLWhereExpression("title LIKE ?", "%n%"))

2016-11-26T21:58:47.15 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE title LIKE '%n%' ORDER BY articles.id ASC LIMIT 1

0.000939 seconds (16 allocations: 576 bytes)

App.Article
+==============+===============================================================================+
|          key |                                                                         value |
+==============+===============================================================================+
|           id |                                                            Nullable{Int32}(1) |
+--------------+-------------------------------------------------------------------------------+
...
+--------------+-------------------------------------------------------------------------------+
|        title |                              Nobis provident dolor sit voluptatibus pariatur. |
+--------------+-------------------------------------------------------------------------------+

julia> SearchLight.find_one_by!!(Article, SQLWhereExpression("title LIKE ?", "foo bar baz"))

2016-11-26T21:59:39.651 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE title LIKE 'foo bar baz' ORDER BY articles.id ASC LIMIT 1

0.000764 seconds (16 allocations: 576 bytes)

------ NullException ------------------- Stacktrace (most recent call last)

 [1] — find_one_by!!(::Type{App.Article}, ::SearchLight.SQLWhereExpression) at SearchLight.jl:295

 [2] — |>(::Nullable{App.Article}, ::Base.#get) at operators.jl:350

 [3] — get at nullable.jl:62 [inlined]

NullException()
```
"""
function find_one_by!!{T<:AbstractModel}(m::Type{T}, column_name::Any, value::Any; order = SQLOrder(m()._id)) :: T
  find_one_by(m, column_name, value, order = order) |> Base.get
end
function find_one_by!!{T<:AbstractModel}(m::Type{T}, sql_expression::SQLWhereExpression; order = SQLOrder(m()._id)) :: T
  find_one_by(m, sql_expression, order = order) |> Base.get
end


"""
    find_one{T<:AbstractModel}(m::Type{T}, value::Any) :: Nullable{T}

Executes a SQL `SELECT` query against the database, applying a `WHERE` filter using
`SearchLight`s `_id` column and the `value`.
Returns the result as a `Nullable{T<:AbstractModel}`.

# Examples
```julia
julia> SearchLight.find_one(Article, 1)

2016-11-26T22:29:11.443 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE (\"id\" = 1) ORDER BY articles.id ASC LIMIT 1

0.000754 seconds (16 allocations: 576 bytes)

Nullable{App.Article}(
App.Article
+==============+===============================================================================+
|          key |                                                                         value |
+==============+===============================================================================+
|           id |                                                            Nullable{Int32}(1) |
+--------------+-------------------------------------------------------------------------------+
...
)
```
"""
function find_one{T<:AbstractModel}(m::Type{T}, value::Any) :: Nullable{T}
  find_one_by(m, SQLColumn(m()._id), SQLInput(value))
end


"""
    find_one!!{T<:AbstractModel}(m::Type{T}, value::Any) :: T

Similar to `find_one` but also attempts to get the value inside the `Nullable`.
Returns the value if is not `NULL`. Throws a `NullException` otherwise.

# Examples
```julia
julia> SearchLight.find_one!!(Article, 36)

2016-11-26T22:35:46.166 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE (\"id\" = 36) ORDER BY articles.id ASC LIMIT 1

0.000742 seconds (16 allocations: 576 bytes)

App.Article
+==============+=========================================================+
|          key |                                                   value |
+==============+=========================================================+
|           id |                                     Nullable{Int32}(36) |
+--------------+---------------------------------------------------------+
...

julia> SearchLight.find_one!!(Article, 387)

2016-11-26T22:36:22.492 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" WHERE (\"id\" = 387) ORDER BY articles.id ASC LIMIT 1

0.000915 seconds (16 allocations: 576 bytes)

------ NullException ------------------- Stacktrace (most recent call last)

 [1] — find_one!!(::Type{App.Article}, ::Int64) at SearchLight.jl:333

 [2] — |>(::Nullable{App.Article}, ::Base.#get) at operators.jl:350

 [3] — get at nullable.jl:62 [inlined]

NullException()
```
"""
function find_one!!{T<:AbstractModel}(m::Type{T}, value::Any) :: T
  find_one(m, value) |> Base.get
end


"""
    rand{T<:AbstractModel}(m::Type{T}; limit = 1) :: Vector{T}

Executes a SQL `SELECT` query against the database, `SORT`ing the results randomly and applying a `LIMIT` of `limit`.
Returns the resultset as a `Vector{T<:AbstractModel}`.

# Examples
```julia
julia> SearchLight.rand(Article)

2016-11-26T22:39:58.545 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" ORDER BY random() ASC LIMIT 1

0.007991 seconds (16 allocations: 576 bytes)

1-element Array{App.Article,1}:

App.Article
+==============+==========================================================================================+
|          key |                                                                                    value |
+==============+==========================================================================================+
|           id |                                                                      Nullable{Int32}(16) |
+--------------+------------------------------------------------------------------------------------------+
...

julia> SearchLight.rand(Article, limit = 3)

2016-11-26T22:40:58.156 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" ORDER BY random() ASC LIMIT 3

0.000809 seconds (16 allocations: 576 bytes)

3-element Array{App.Article,1}:
...
```
"""
function rand{T<:AbstractModel}(m::Type{T}; limit = 1) :: Vector{T}
  find(m, SQLQuery(limit = SQLLimit(limit), order = [SQLOrder("random()", raw = true)]))
end


"""
    rand_one{T<:AbstractModel}(m::Type{T}) :: Nullable{T}

Similar to `SearchLight.rand` -- returns one random instance of {T<:AbstractModel}, wrapped into a Nullable{T}.

# Examples
```julia
julia> SearchLight.rand_one(Article)

2016-11-26T22:46:11.47100000000000003 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\" ORDER BY random() ASC LIMIT 1

0.001087 seconds (16 allocations: 576 bytes)

Nullable{App.Article}(
App.Article
+==============+=======================================================================================+
|          key |                                                                                 value |
+==============+=======================================================================================+
|           id |                                                                   Nullable{Int32}(37) |
+--------------+---------------------------------------------------------------------------------------+
...
)
```
"""
function rand_one{T<:AbstractModel}(m::Type{T}) :: Nullable{T}
  to_nullable(rand(m, limit = 1))
end


"""
    all{T<:AbstractModel}(m::Type{T}) :: Vector{T}

Executes a SQL `SELECT` query against the database and return all the results. Alias for `find(m)`
Returns the resultset as a `Vector{T<:AbstractModel}`.

# Examples
```julia
julia> SearchLight.all(Article)

2016-11-26T23:09:57.976 - info: SQL QUERY: SELECT \"articles\".\"id\" AS \"articles_id\", \"articles\".\"title\" AS \"articles_title\", \"articles\".\"summary\" AS \"articles_summary\", \"articles\".\"content\" AS \"articles_content\", \"articles\".\"updated_at\" AS \"articles_updated_at\", \"articles\".\"published_at\" AS \"articles_published_at\", \"articles\".\"slug\" AS \"articles_slug\" FROM \"articles\"

0.003656 seconds (16 allocations: 576 bytes)

38-element Array{App.Article,1}:
...
```
"""
function all{T<:AbstractModel}(m::Type{T}) :: Vector{T}
  find(m)
end


"""
    save{T<:AbstractModel}(m::T; conflict_strategy = :error)

Attempts to persist the model's data to the database. Returns boolean `true` if successful, `false` otherwise.

# Examples
```julia

```
"""
function save{T<:AbstractModel}(m::T; conflict_strategy = :error) :: Bool
  try
    _save!!(m, conflict_strategy = conflict_strategy)
    true
  catch ex
    Logger.log(ex)
    false
  end
end


"""
   save!!{T<:AbstractModel}(m::T; conflict_strategy = :error, skip_validation = false)

Similar to `save` but it returns the model reloaded from the database, applying callbacks. Throws an exception if the model can't be persisted.

# Examples
```julia

```
"""
function save!{T<:AbstractModel}(m::T; conflict_strategy = :error)
  save!!(m, conflict_strategy = conflict_strategy)
end
function save!!{T<:AbstractModel}(m::T; conflict_strategy = :error, skip_validation = false)
  find_one_by!!(typeof(m), Symbol(m._id), (_save!!(m, conflict_strategy = conflict_strategy, skip_validation = skip_validation))[1, Symbol(m._id)])
end
function _save!!{T<:AbstractModel}(m::T; conflict_strategy = :error, skip_validation = false)
  ! skip_validation && ! Validation.validate!(m) && error("SearchLight validation error(s) for $(typeof(m)) \n $(join(Validation.errors(m), "\n "))")

  invoke_callback(m, :before_save)

  result = query(to_store_sql(m, conflict_strategy = conflict_strategy))

  invoke_callback(m, :after_save)

  result
end

function invoke_callback{T<:AbstractModel}(m::T, callback::Symbol)
  in(callback, fieldnames(m)) ? (true, getfield(m, callback)(m), m) : (false, nothing, m)
end

"""
    update_with!{T<:AbstractModel}(m::T, w::T)
    update_with!{T<:AbstractModel}(m::T, w::Dict)

Copies the data from `w` into the corresponding properties in `m`. Returns `m`
"""
function update_with!{T<:AbstractModel}(m::T, w::T)
  for fieldname in fieldnames(typeof(m))
    ( startswith(string(fieldname), "_") || string(fieldname) == m._id ) && continue
    setfield!(m, fieldname, getfield(w, fieldname))
  end

  m
end
function update_with!{T<:AbstractModel}(m::T, w::Dict)
  for fieldname in fieldnames(typeof(m))
    ( startswith(string(fieldname), "_") || string(fieldname) == m._id ) && continue
    haskey(w, fieldname) && setfield!(m, fieldname, w[fieldname])
  end

  m
end

"""
    update_with!!{T<:AbstractModel}(m::T, w::Union{T,Dict})

Similar to `update_with` but also calls `save!!` on `m`.
"""
function update_with!!{T<:AbstractModel}(m::T, w::Union{T,Dict})
  SearchLight.save!!(update_with!(m, w)) |> Base.get
end

"""
    create_or_update_by!!{T<:AbstractModel}(m::T, property::Symbol[, value::Any])

Tries to find `m` by `property` and `value`. If value is not provided, it uses the corresponding value of `m`.
If `m` was already persisted, it is updated. If not, it is persisted as a new row.
"""
function create_or_update_by!!{T<:AbstractModel}(m::T, property::Symbol, value::Any)
  existing = find_one_by(typeof(m), property, value)
  if ! isnull(existing)
    existing = Base.get(existing)

    for fieldname in fieldnames(typeof(m))
      ( startswith(string(fieldname), "_") || string(fieldname) == m._id ) && continue
      setfield!(existing, fieldname, getfield(m, fieldname))
    end

    return SearchLight.save!!(existing)
  else
    return SearchLight.save!!(m)
  end
end
function create_or_update_by!!{T<:AbstractModel}(m::T, property::Symbol)
  create_or_update_by!!(m, property, getfield(m, property))
end

"""
    find_one_by_or_create{T<:AbstractModel}(m::Type{T}, property::Any, value::Any)

Tries to find `m` by `property` and `value`. If it exists, it is returned. If not, a new instance is created, `property` is set to `value` and the instance is returned.
"""
function find_one_by_or_create{T<:AbstractModel}(m::Type{T}, property::Any, value::Any)
  lookup = find_one_by(m, SQLColumn(property), SQLInput(value))
  ! isnull( lookup ) && return lookup

  _m = disposable_instance(m)
  setfield!(_m, Symbol(property), value)

  _m
end

#
# Object generation
#

"""
   to_models{T<:AbstractModel}(m::Type{T}, df::DataFrames.DataFrame)

Converts `df` to a Vector{T}
"""
function to_models{T<:AbstractModel}(m::Type{T}, df::DataFrames.DataFrame)
  models = OrderedDict{DbId,T}()
  dfs = df_result_to_models_data(m, df)::Dict{String,DataFrame} # this splits the result data frame into multiple dataframes, one for each table contained in the result

  row_count::Int = 1
  for row in eachrow(df)
    main_model::T = to_model(m, dfs[disposable_instance(m)._table_name][row_count, :])

    if haskey(models, getfield(main_model, Symbol(disposable_instance(m)._id)))
      main_model = models[getfield(main_model, Symbol(disposable_instance(m)._id)) |> Base.get]
    end

    for relationship in relationships(m)
      r::SQLRelation, r_type::Symbol = relationship

      is_lazy(r) && continue

      related_model = r.model_name
      related_model_df::DataFrames.DataFrame = dfs[disposable_instance(related_model)._table_name][row_count, :]

      if r_type == RELATIONSHIP_HAS_ONE || r_type == RELATIONSHIP_BELONGS_TO
        r = set_relationship_data(r, related_model, related_model_df)
      elseif r_type == RELATIONSHIP_HAS_MANY
        r = set_relationship_data_array(r, related_model, related_model_df)
      end

      model_rels::Vector{SQLRelation} = getfield(main_model, r_type)
      isnull(model_rels[1].data) ? model_rels[1] = r : push!(model_rels, r)
    end

    if ! haskey(models, getfield(main_model, Symbol(disposable_instance(m)._id)))
      models[getfield(main_model, Symbol(disposable_instance(m)._id)) |> Base.get] = main_model
    end

    row_count += 1
  end

  models |> values |> collect
end

"""
    set_relationship_data{T<:AbstractModel}(r::SQLRelation, related_model::Type{T}, related_model_df::DataFrames.DataFrame)

Extracts related model data and sets it into the relationship
"""
function set_relationship_data{T<:AbstractModel}(r::SQLRelation, related_model::Type{T}, related_model_df::DataFrames.DataFrame)
  r.data = Nullable( to_model(related_model, related_model_df) )
  r
end

"""
    set_relationship_data_array{T<:AbstractModel}(r::SQLRelation, related_model::Type{T}, related_model_df::DataFrames.DataFrame)

Sets relationship data for one to many relationships
"""
function set_relationship_data_array{T<:AbstractModel}(r::SQLRelation, related_model::Type{T}, related_model_df::DataFrames.DataFrame)
  data =  if isnull(r.data)
            RelationshipDataArray()
          else
            Base.get(r.data)
          end
  push!(data, to_model(related_model, related_model_df))
  r.data = data

  r
end

"""
    to_model{T<:AbstractModel}(m::Type{T}, row::DataFrames.DataFrameRow)

Converts a DataFrame row to a SearchLight model instance
"""
function to_model{T<:AbstractModel}(m::Type{T}, row::DataFrames.DataFrameRow)
  _m = disposable_instance(m)
  obj = m()
  sf = settable_fields(_m, row)
  set_fields = Symbol[]

  for field in sf
    unq_field = from_fully_qualified(_m, field)

    isna(row[field]) && continue # if it's NA we just leave the default value of the empty obj

    value = if in(:on_hydration!, fieldnames(_m))
              try
                _m, value = _m.on_hydration!(_m, unq_field, row[field])
                value
              catch ex
                Logger.log("Failed to hydrate! field $unq_field ($field)", :debug)
                Logger.log(ex)

                row[field]
              end
            elseif in(:on_hydration, fieldnames(_m))
              try
                _m.on_hydration(_m, unq_field, row[field])
              catch ex
                Logger.log("Failed to hydrate field $unq_field ($field)", :debug)
                Logger.log(ex)

                row[field]
              end
            else
              row[field]
            end
    try
      setfield!(obj, unq_field, convert(typeof(getfield(_m, unq_field)), value))
    catch ex
      Logger.log(ex, :err)
      Logger.log("obj = $(typeof(obj)) -- field = $unq_field -- value = $value -- type = $( typeof(getfield(_m, unq_field)) )")
      rethrow(ex)
    end

    push!(set_fields, unq_field)
  end

  for field in fieldnames(_m)
    if ! in(field, set_fields)
      try
        setfield!(obj, field, getfield(_m, field))
      catch ex
        Logger.log(ex)
        Logger.log(field)
      end
    end
  end

  status = invoke_callback(obj, :after_hydration)
  status[1] && (obj = status[2])

  obj
end

"""
    to_model{T<:AbstractModel}(m::Type{T}, df::DataFrames.DataFrame)

Converts a DataFrame to a SearchLight model instance
"""
function to_model{T<:AbstractModel}(m::Type{T}, df::DataFrames.DataFrame)
  for row in eachrow(df)
    return to_model(m, row)
  end
end

#
# Query generation
#

"""
    to_select_part{T<:AbstractModel}(m::Type{T}, cols::Vector{SQLColumn}[, joins = SQLJoin[] ])
    to_select_part{T<:AbstractModel}(m::Type{T}, c::SQLColumn)
    to_select_part{T<:AbstractModel}(m::Type{T}, c::String)
    to_select_part{T<:AbstractModel}(m::Type{T})

Generates the SELECT part of the query
"""
function to_select_part{T<:AbstractModel}(m::Type{T}, cols::Vector{SQLColumn}, joins = SQLJoin[])
  Database.to_select_part(m, cols, joins)
end
function to_select_part{T<:AbstractModel}(m::Type{T}, c::SQLColumn)
  to_select_part(m, [c])
end
function to_select_part{T<:AbstractModel}(m::Type{T}, c::String)
  to_select_part(m, SQLColumn(c, raw = c == "*"))
end
function to_select_part{T<:AbstractModel}(m::Type{T})
  to_select_part(m, SQLColumn[])
end

"""
    to_from_part{T<:AbstractModel}(m::Type{T})

Generates the FROM part of the query
"""
function to_from_part{T<:AbstractModel}(m::Type{T})
  Database.to_from_part(m)
end

"""
    to_where_part{T<:AbstractModel}(m::Type{T}, w::Vector{SQLWhereEntity})

Generates the WHERE part of the query
"""
function to_where_part{T<:AbstractModel}(m::Type{T}, w::Vector{SQLWhereEntity})
  Database.to_where_part(m, w)
end

function required_scopes{T<:AbstractModel}(m::Type{T})
  Database.required_scopes(m)
end

function scopes{T<:AbstractModel}(m::Type{T})
  Database.scopes(m)
end

"""
    to_order_part{T<:AbstractModel}(m::Type{T}, o::Vector{SQLOrder})

Generates the ORDER part of the query
"""
function to_order_part{T<:AbstractModel}(m::Type{T}, o::Vector{SQLOrder})
  Database.to_order_part(m, o)
end

"""
    to_group_part(g::Vector{SQLColumn})

Generates the GROUP part of the query
"""
function to_group_part(g::Vector{SQLColumn})
  Database.to_group_part(g)
end

"""
    to_limit_part(l::SQLLimit)

Generates the LIMIT part of the query
"""
function to_limit_part(l::SQLLimit)
  Database.to_limit_part(l)
end

"""
    to_offset_part(o::Int)

Generates the OFFSET part of the query
"""
function to_offset_part(o::Int)
  Database.to_offset_part(o)
end

"""
    to_having_part(h::Vector{SQLHaving})

Generates the HAVING part of the query
"""
function to_having_part(h::Vector{SQLHaving})
  Database.to_having_part(h)
end


"""
    to_join_part{T<:AbstractModel}(m::Type{T}[, joins = SQLJoin[] ])

Generates the JOIN part of the query
"""
function to_join_part{T<:AbstractModel}(m::Type{T}, joins = SQLJoin[])
  Database.to_join_part(m, joins)
end

"""
    relationships{T<:AbstractModel}(m::Type{T})

Returns the vector of relationships for the given model type
"""
function relationships{T<:AbstractModel}(m::Type{T})
  _m = disposable_instance(m)

  rls = []

  for r in direct_relationships()
    if has_field(_m, r)
      relationship = getfield(_m, r)
      if ! isempty(relationship)
        for rel in relationship
          push!(rls, (rel, r))
        end
      end
    end
  end

  rls
end

"""
    relationship{T<:AbstractModel, R<:AbstractModel}(m::T, model_name::Type{R}, relationship_type::Symbol)::Nullable{SQLRelation}

Gets the relationship instance of `relationship_type` for the model instance `m` and `model_name`
"""
function relationship{T<:AbstractModel, R<:AbstractModel}(m::T, model_name::Type{R}, relationship_type::Symbol)::Nullable{SQLRelation}
  nullable_defined_rels::Nullable{Vector{SQLRelation}} = getfield(m, relationship_type)
  if ! isnull(nullable_defined_rels)
    defined_rels::Vector{SQLRelation} = Base.get(nullable_defined_rels)

    for rel::SQLRelation in defined_rels
      if rel.model_name == model_name || split(string(rel.model_name), ".")[end] == string(model_name)
        return Nullable{SQLRelation}(rel)
      else
        Logger.log("Must check this: $(rel.model_name) == $(model_name) at $(@__FILE__) $(@__LINE__)", :debug)
      end
    end
  end

  Nullable{SQLRelation}()
end

function relationship_data{T<:AbstractModel, R<:AbstractModel}(m::T, model_name::Type{R}, relationship_type::Symbol)
  rel = relationship(m, model_name, relationship_type) |> Base.get
  if isnull(rel.data)
    rel.data = get_relationship_data(m, rel, relationship_type)
  end

  rel.data
end

function relationship_data!!{T<:AbstractModel, R<:AbstractModel}(m::T, model_name::Type{R}, relationship_type::Symbol)
  Base.get( relationship_data(m, model_name, relationship_type) )::Union{RelationshipData, RelationshipDataArray}
end

function get_relationship_data{T<:AbstractModel}(m::T, rel::SQLRelation, relationship_type::Symbol)
  conditions = SQLWhere[]
  limit = if relationship_type == RELATIONSHIP_HAS_ONE || relationship_type == RELATIONSHIP_BELONGS_TO
            1
          else
            "ALL"
          end
  where = if relationship_type == RELATIONSHIP_HAS_ONE || relationship_type == RELATIONSHIP_HAS_MANY
            SQLColumn( ( (lowercase(string(typeof(m))) |> strip_module_name) * "_" * m._id |> escape_column_name), raw = true ), m.id
          elseif relationship_type == RELATIONSHIP_BELONGS_TO
            _r = (rel.model_name)()
            SQLColumn(to_fully_qualified(_r._id, _r._table_name), raw = true), getfield(m, Symbol((lowercase(string(typeof(_r))) |> strip_module_name) * "_" * _r._id)) |> Base.get
          end
  push!(conditions, SQLWhere(where...))
  data = SearchLight.find( rel.model_name, SQLQuery( where = conditions, limit = SQLLimit(limit) ) )

  isempty(data) && return Nullable{RelationshipData}()

  if relationship_type == RELATIONSHIP_HAS_ONE || relationship_type == RELATIONSHIP_BELONGS_TO
    return Nullable{RelationshipData}(first(data))
  else
    return Nullable{RelationshipDataArray}(data)
  end

  Nullable{RelationshipData}()
end

function relationships_tables_names{T<:AbstractModel}(m::Type{T})
  tables_names = String[]
  for r in relationships(m)
    r, r_type = r
    rmdl = disposable_instance(r.model_name)
    push!(tables_names, rmdl._table_name)
  end

  tables_names
end

function extract_columns_names(tables_names::Vector{String}, df::DataFrame)
  tables_columns = Dict()

  for t in tables_names
    tables_columns[t] = Symbol[]
  end

  for dfc in names(df)
    table_name = ""
    sdfc = string(dfc)

    ! contains(sdfc, "_") && continue

    for t in tables_names
      if startswith(sdfc, t)
        table_name = t
        break
      end
    end

    ! in(table_name, tables_names) && continue

    push!(tables_columns[table_name], dfc)
  end

  tables_columns
end

function split_dfs_by_table(tables_names::Vector{String}, tables_columns::Dict, df::DataFrame)
  sub_dfs = Dict{String,DataFrame}()

  for t in tables_names
    sub_dfs[t] = df[:, tables_columns[t]]
  end

  sub_dfs
end

function df_result_to_models_data{T<:AbstractModel}(m::Type{T}, df::DataFrame)::Dict{String,DataFrame}
  _m::T = disposable_instance(m)
  tables_names = vcat(String[_m._table_name], relationships_tables_names(m))

  split_dfs_by_table( tables_names,
                      extract_columns_names(tables_names, df),
                      df)::Dict{String,DataFrame}
end

function relation_to_sql{T<:AbstractModel}(m::T, rel::Tuple{SQLRelation,Symbol})
  Database.relation_to_sql(m, rel)
end

function to_fetch_sql{T<:AbstractModel, N<:AbstractModel}(m::Type{T}, q::SQLQuery, joins::Vector{SQLJoin{N}})
  Database.to_fetch_sql(m, q, joins)
end
function to_fetch_sql{T<:AbstractModel}(m::Type{T}, q::SQLQuery)
  Database.to_fetch_sql(m, q)
end

function to_store_sql{T<:AbstractModel}(m::T; conflict_strategy = :error) # upsert strateygy = :none | :error | :ignore | :update
  Database.to_store_sql(m, conflict_strategy = conflict_strategy)
end

function prepare_for_db_save{T<:AbstractModel}(m::T, field::Symbol, value)
  value = if in(:on_dehydration, fieldnames(m))
            try
              m.on_dehydration(m, field, value)
            catch ex
              Logger.log("Failed to dehydrate field $field", :debug)
              Logger.log(ex)

              value
            end
          else
            value
          end

  SQLInput(value)
end

#
# delete methods
#

function delete_all{T<:AbstractModel}(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false)
  Database.delete_all(m, truncate = truncate, reset_sequence = reset_sequence, cascade = cascade)
end

function delete{T<:AbstractModel}(m::T)
  Database.delete(m)
end

#
# query execution
#

function query(sql::String)
  Database.query_df(sql)
end

#
# sql utility queries
#

function count{T<:AbstractModel}(m::Type{T}, q::SQLQuery = SQLQuery())::Int
  Database.count(m, q)
end

#
# ORM utils
#

function disposable_instance(m)
  m()
end

function columns(m)
  Database.table_columns(disposable_instance(m)._table_name)
end

function is_persisted{T<:AbstractModel}(m::T)
  ! ( isa(getfield(m, Symbol(m._id)), Nullable) && isnull( getfield(m, Symbol(m._id)) ) )
end

function persistable_fields{T<:AbstractModel}(m::T; fully_qualified::Bool = false)
  object_fields = map(x -> string(x), fieldnames(m))
  db_columns = columns(typeof(m))[:column_name]

  isempty(db_columns) && Genie.config.log_db &&
    Logger.log("No columns retrieved for $(typeof(m)) - check if the table exists and the model is properly configured.", :err)

  pst_fields = intersect(object_fields, db_columns)
  fully_qualified ? to_fully_qualified_sql_column_names(m, pst_fields) : pst_fields
end

function settable_fields{T<:AbstractModel}(m::T, row::DataFrames.DataFrameRow)
  df_cols::Array{Symbol,1} = names(row)
  fields = is_fully_qualified(m, df_cols[1]) ? to_sql_column_names(m, fieldnames(m)) : fieldnames(m)
  intersect(fields, df_cols)
end

#
# Data sanitization
#

function to_sql(sql::String, params::Tuple)
  i = 0
  function splat_params(_)
    i += 1
    Database.escape_value(params[i])
  end

  sql = replace(sql, '?', splat_params)
end
function to_sql(sql::String, params::Dict)
  function dict_params(key)
    key = Symbol(replace(key, r"^:", ""))
    Database.escape_value(params[key])
  end

  replace(sql, r":([a-zA-Z0-9]*)", dict_params)
end

function escape_column_name(c::SQLColumn)
  if ! c.escaped && ! c.raw
    val = c.table_name != "" && ! startswith(c.value, (c.table_name * ".")) && ! is_fully_qualified(c.value) ? c.table_name * "." * c.value : c.value
    c.value = escape_column_name(val)
    c.escaped = true
  end

  c
end
function escape_column_name(s::String)
  join(map(x -> Database.escape_column_name(string(x)), split(s, ".")), ".")
end

function escape_value(i::SQLInput)
  (i.value == "NULL" || i.value == "NOT NULL") && return i

  if ! i.escaped && ! i.raw
    i.value = Database.escape_value(i.value)
    i.escaped = true
  end

  return i
end

#
# utility functions
#

function id{T<:AbstractModel}(m::T)
  m._id
end

function table_name{T<:AbstractModel}(m::T)
  m._table_name
end

function validator{T<:AbstractModel}(m::T)
  Validation.validator(m)
end

function has_field{T<:AbstractModel}(m::T, f::Symbol)
  in(f, fieldnames(m))
end

function strip_table_name{T<:AbstractModel}(m::T, f::Symbol)
  replace(string(f), Regex("^$(m._table_name)_"), "", 1) |> Symbol
end

function is_fully_qualified{T<:AbstractModel}(m::T, f::Symbol)
  startswith(string(f), m._table_name) && has_field(m, strip_table_name(m, f))
end

function is_fully_qualified(s::String)
  ! startswith(s, ".") && contains(s, ".")
end

function from_fully_qualified{T<:AbstractModel}(m::T, f::Symbol)
  is_fully_qualified(m, f) ? strip_table_name(m, f) : f
end
function from_fully_qualified(s::String)
  arr = split(s, ".")
  (arr[1], arr[2])
end

function strip_module_name(s::String)
  split(s, ".") |> last
end

function to_fully_qualified(v::String, t::String)
  t * "." * v
end
function to_fully_qualified{T<:AbstractModel}(m::T, v::String)
  to_fully_qualified(v, m._table_name)
end
function to_fully_qualified{T<:AbstractModel}(m::T, c::SQLColumn)
  c.raw && return c.value
  to_fully_qualified(c.value, m._table_name)
end
function to_fully_qualified{T<:AbstractModel}(m::Type{T}, c::SQLColumn)
  to_fully_qualified(disposable_instance(m), c)
end

function to_sql_column_names{T<:AbstractModel}(m::T, fields::Array{Symbol,1})
  map(x -> (to_sql_column_name(m, string(x))) |> Symbol, fields)
end

function to_sql_column_name(v::String, t::String)
  str = Util.strip_quotes(t) * "_" * Util.strip_quotes(v)
  if Util.is_quoted(t) && Util.is_quoted(v)
    Util.add_quotes(str)
  else
    str
  end
end
function to_sql_column_name{T<:AbstractModel}(m::T, v::String)
  to_sql_column_name(v, m._table_name)
end
function to_sql_column_name{T<:AbstractModel}(m::T, c::SQLColumn)
  to_sql_column_name(c.value, m._table_name)
end

function to_fully_qualified_sql_column_names{T<:AbstractModel}(m::T, persistable_fields::Vector{String}; escape_columns::Bool = false)
  map(x -> to_fully_qualified_sql_column_name(m, x, escape_columns = escape_columns), persistable_fields)
end

function to_fully_qualified_sql_column_name{T<:AbstractModel}(m::T, f::String; escape_columns::Bool = false, alias::String = "")
  if escape_columns
    "$(to_fully_qualified(m, f) |> escape_column_name) AS $(isempty(alias) ? (to_sql_column_name(m, f) |> escape_column_name) : alias)"
  else
    "$(to_fully_qualified(m, f)) AS $(isempty(alias) ? to_sql_column_name(m, f) : alias)"
  end
end

function from_literal_column_name(c::String)
  result = Dict{Symbol,String}()
  result[:original_string] = c

  # has alias?
  if contains(c, " AS ")
    parts = split(c, " AS ")
    result[:column_name] = parts[1]
    result[:alias] = parts[2]
  else
    result[:column_name] = c
  end

  # is fully qualified?
  if contains(result[:column_name], ".")
    parts = split(result[:column_name], ".")
    result[:table_name] = parts[1]
    result[:column_name] = parts[2]
  end

  result
end

function to_dict{T<:AbstractModel}(m::T; all_fields::Bool = false, expand_nullables::Bool = false, symbolize_keys::Bool = false)
  fields = all_fields ? fieldnames(m) : persistable_fields(m)
  Dict( ( symbolize_keys ? Symbol(f) : string(f) ) => Util.expand_nullable( getfield(m, Symbol(f)), expand = expand_nullables ) for f in fields )
end
function to_dict{T<:GenieType}(m::T)
  Genie.to_dict(m)
end

function to_string_dict{T<:AbstractModel}(m::T; all_fields::Bool = false, all_output::Bool = false)
  fields = all_fields ? fieldnames(m) : persistable_fields(m)
  output_length = all_output ? 100_000_000 : Genie.config.output_length
  response = Dict{String,String}()
  for f in fields
    key = string(f)
    value = string(getfield(m, Symbol(f)))
    if length(value) > output_length
      value = value[1:output_length] * "..."
    end
    response[key] = value
  end

  response
end
function to_string_dict{T<:GenieType}(m::T)
  Genie.to_string_dict(m)
end

function to_nullable{T<:AbstractModel}(result::Vector{T})
  isempty(result) ? Nullable{T}() : Nullable{T}(result |> first)
end

function escape_type(value)
  return if isa(value, String)
    value = replace(value, "\$", "\\\$")
    value = replace(value, "\@", "\\\@")
    "\"$value\""
  elseif isa(value, Char)
    "'$value'"
  else
    value
  end
end

function constantize(s::Symbol, m::Module = Genie)
  string(m) * "." * ucfirst(string(s)) |> parse |> eval
end

function has_relationship{T<:GenieType}(m::T, relationship_type::Symbol)
  has_field(m, relationship_type)
end

function dataframe_to_dict(df::DataFrames.DataFrame)
  result = Dict{Symbol,Any}[]
  for r in eachrow(df)
    push!(result, Dict{Symbol,Any}( [k => r[k] for k in DataFrames.names(df)] ) )
  end

  result
end

function enclosure(v::Any, o::Any)
  in(string(o), ["IN", "in"]) ? "($(string(v)))" : v
end

function convert(::Type{DateTime}, value::String)
  DateParser.parse(DateTime, value)
end

function convert(::Type{Nullable{DateTime}}, value::String)
  DateParser.parse(DateTime, value) |> Nullable
end

function update_query_part{T<:AbstractModel}(m::T)
  Database.update_query_part(m)
end

end

const Model = SearchLight
export Model

const SL = SearchLight
export SL
