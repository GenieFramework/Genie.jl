module Database
using YAML, Genie, Memoize, SearchLight, DataFrames

eval(:(using $(Genie.config.db_adapter)))
eval(:(const DatabaseAdapter = $(Genie.config.db_adapter)))
eval(:(export DatabaseAdapter))


"""
    connect() :: DatabaseHandle
    connect(conn_settings::Dict{String,Any}) :: DatabaseHandle
    connection() :: DatabaseHandle

Connects to the DB and returns a database handler. If used without arguments, it defaults to using `Genie.config.db_config_settings`

# Examples
```julia
julia> Database.connect()
PostgreSQL.PostgresDatabaseHandle(Ptr{Void} @0x00007fbf3839f360,0x00000000,false)

julia> dict = Genie.config.db_config_settings
Dict{String,Any} with 6 entries:
  "host"     => "localhost"
  "password" => "adrian"
  "username" => "adrian"
  "port"     => 5432
  "database" => "blogjl_dev"
  "adapter"  => "PostgreSQL"

julia> Database.connect(dict)
PostgreSQL.PostgresDatabaseHandle(Ptr{Void} @0x00007fbf3839f360,0x00000000,false)
```
"""
function connect() :: DatabaseHandle
  connect(Genie.config.db_config_settings)
end
@memoize function connect(conn_settings::Dict{String,Any})
  DatabaseAdapter.connect(conn_settings) :: DatabaseHandle
end
function connection() :: DatabaseHandle
  connect()
end


"""
    query_tools() :: Tuple{DatabaseHandle,Symbol}

Returns a Tuple consisting of the database handle of the current DB connection and a symbol
representing the type of the adapter.

# Examples
```julia
julia> Database.query_tools()
(PostgreSQL.PostgresDatabaseHandle(Ptr{Void} @0x00007fbf3839f360,0x00000000,false),:PostgreSQL)
```
"""
function query_tools() :: Tuple{DatabaseHandle,Symbol}
  (connect(), DatabaseAdapter.db_adapter())
end


"""
    create_database() :: Bool
    create_database(db_name::String) :: Bool

Invokes the database adapter's create database method. If invoked without param, it defaults to the
database name defined in `Genie.config.db_config_settings`
"""
function create_database() :: Bool
  create_database(Genie.config.db_config_settings["database"])
end
function create_database(db_name::String) :: Bool
  DatabaseAdapter.create_database(db_name)
end


"""
    create_migrations_table() :: Bool

Invokes the database adapter's create migrations table method. If invoked without param, it defaults to the
database name defined in `Genie.config.db_migrations_table_name`
"""
function create_migrations_table() :: Bool
  create_migrations_table(Genie.config.db_migrations_table_name)
end
function create_migrations_table(table_name::String) :: Bool
  DatabaseAdapter.create_migrations_table(table_name)
end


"""

"""
function query(sql::AbstractString; system_query::Bool = false) :: ResultHandle
  DatabaseAdapter.query(sql, system_query || Genie.config.suppress_output, connection())
end


@memoize function escape_column_name(c::AbstractString)
  DatabaseAdapter.escape_column_name(c, connection()) :: String
end


@memoize function escape_value(v::Union{AbstractString,Real})
  DatabaseAdapter.escape_value(v, connection()) :: String
end


@memoize function table_columns(table_name::AbstractString)
  query_df(DatabaseAdapter.table_columns_sql(table_name), suppress_output = true) :: DataFrames.DataFrame
end


"""

"""
function query_df(sql::AbstractString; suppress_output::Bool = false) :: DataFrames.DataFrame
  DatabaseAdapter.query_df(sql, (suppress_output || Genie.config.suppress_output), connection())
end


"""

"""
function relation_to_sql{T<:AbstractModel}(m::T, rel::Tuple{SQLRelation,Symbol}) :: String
  DatabaseAdapter.relation_to_sql(m, rel)
end


"""

"""
function to_find_sql{T<:AbstractModel, N<:AbstractModel}(m::Type{T}, q::SQLQuery, joins::Vector{SQLJoin{N}}) :: String
  DatabaseAdapter.to_find_sql(m, q, joins)
end
function to_find_sql{T<:AbstractModel}(m::Type{T}, q::SQLQuery) :: String
  DatabaseAdapter.to_find_sql(m, q)
end
const to_fetch_sql = to_find_sql


"""

"""
function to_store_sql{T<:AbstractModel}(m::T; conflict_strategy = :error) :: String # upsert strateygy = :none | :error | :ignore | :update
  DatabaseAdapter.to_store_sql(m, conflict_strategy = conflict_strategy)
end


"""

"""
function delete_all{T<:AbstractModel}(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false) :: Void
  DatabaseAdapter.delete_all(m, truncate = truncate, reset_sequence = reset_sequence, cascade = cascade)
end


"""

"""
function delete{T<:AbstractModel}(m::T) :: T
  DatabaseAdapter.delete(m)
end


"""

"""
function count{T<:AbstractModel}(m::Type{T}, q::SQLQuery = SQLQuery()) :: Int
  DatabaseAdapter.count(m, q)
end


"""

"""
function update_query_part{T<:AbstractModel}(m::T) :: String
  DatabaseAdapter.update_query_part(m)
end


"""

"""
function to_select_part{T<:AbstractModel}(m::Type{T}, cols::Vector{SQLColumn}, joins = SQLJoin[]) :: String
  DatabaseAdapter.to_select_part(m, cols, joins)
end


"""

"""
function to_from_part{T<:AbstractModel}(m::Type{T}) :: String
  DatabaseAdapter.to_from_part(m)
end


"""

"""
function to_where_part{T<:AbstractModel}(m::Type{T}, w::Vector{SQLWhereEntity}, scopes::Vector{Symbol}) :: String
  DatabaseAdapter.to_where_part(m, w, scopes)
end
function to_where_part(w::Vector{SQLWhereEntity}) :: String
  DatabaseAdapter.to_where_part(w)
end


"""

"""
function required_scopes{T<:AbstractModel}(m::Type{T}) :: Vector{SQLWhereEntity}
  DatabaseAdapter.required_scopes(m)
end


"""

"""
function scopes{T<:AbstractModel}(m::Type{T}) :: Dict{Symbol,Vector{SQLWhereEntity}}
  DatabaseAdapter.scopes(m)
end


"""

"""
function to_order_part{T<:AbstractModel}(m::Type{T}, o::Vector{SQLOrder}) :: String
  DatabaseAdapter.to_order_part(m, o)
end


"""

"""
function to_group_part(g::Vector{SQLColumn}) :: String
  DatabaseAdapter.to_group_part(g)
end


"""

"""
function to_limit_part(l::SQLLimit) :: String
  DatabaseAdapter.to_limit_part(l)
end


"""

"""
function to_offset_part(o::Int) :: String
  DatabaseAdapter.to_offset_part(o)
end


"""

"""
function to_having_part(h::Vector{SQLHaving}) :: String
  DatabaseAdapter.to_having_part(h)
end


"""

"""
function to_join_part{T<:AbstractModel}(m::Type{T}, joins = SQLJoin[]) :: String
  DatabaseAdapter.to_join_part(m, joins)
end


"""
  columns_from_joins() :: SQLColumn

Extracts columns from joins param and adds to be used for the SELECT part
"""
function columns_from_joins(joins::Vector{SQLJoin}) :: Vector{SQLColumn}
  jcols = SQLColumn[]
  for j in joins
    jcols = vcat(jcols, j.columns)
  end

  jcols
end


"""

"""
function prepare_column_name(column::SQLColumn) :: String
  if column.raw
    column.value |> string
  else
    column_data = SearchLight.from_literal_column_name(column.value)
    if ! haskey(column_data, :table_name)
      column_data[:table_name] = _m._table_name
    end
    if ! haskey(column_data, :alias)
      column_data[:alias] = ""
    end

    DatabaseAdapter.column_data_to_column_name(column, column_data)
  end
end


"""

"""
function to_select_part{T<:AbstractModel}(m::Type{T}, cols::Vector{SQLColumn}, joins = SQLJoin[]) :: String
  _m::T = m()

  joined_tables = []

  if has_relation(_m, RELATION_HAS_ONE)
    rels = _m.has_one
    joined_tables = vcat(joined_tables, map(x -> is_lazy(x) ? nothing : (x.model_name)(), rels))
  end

  if has_relation(_m, RELATION_HAS_MANY)
    rels = _m.has_many
    joined_tables = vcat(joined_tables, map(x -> is_lazy(x) ? nothing : (x.model_name)(), rels))
  end

  if has_relation(_m, RELATION_BELONGS_TO)
    rels = _m.belongs_to
    joined_tables = vcat(joined_tables, map(x -> is_lazy(x) ? nothing : (x.model_name)(), rels))
  end

  filter!(x -> x != nothing, joined_tables)

  if ! isempty(cols)
    table_columns = []
    cols = vcat(cols, columns_from_joins())

    for column in cols
      push!(table_columns, prepare_column_name(column))
    end

    return join(table_columns, ", ")
  else
    table_columns = join(to_fully_qualified_sql_column_names(_m, persistable_fields(_m), escape_columns = true), ", ")
    table_columns = isempty(table_columns) ? AbstractString[] : vcat(table_columns, map(x -> prepare_column_name(x), columns_from_joins(joins)))

    related_table_columns = String[]
    for rels in map(x -> to_fully_qualified_sql_column_names(x, persistable_fields(x), escape_columns = true), joined_tables)
      for col in rels
        push!(related_table_columns, col)
      end
    end

    return join([table_columns ; related_table_columns], ", ")
  end
end

end
