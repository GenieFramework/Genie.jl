module Database
using YAML, Genie, Memoize, SearchLight

eval(:(using $(Genie.config.db_adapter)))
eval(:(const DatabaseAdapter = $(Genie.config.db_adapter)))
eval(:(export DatabaseAdapter))

@memoize function db_connect()
  DatabaseAdapter.adapter_connect(Genie.config.db_config_settings)
end

@memoize function query_tools()
  db_connect(), DatabaseAdapter.db_adapter()
end

function create_database()
  Logger.log("Not implemented - please manually create the database first, if it does not already exist", :debug)
end

function create_migrations_table()
  query(DatabaseAdapter.adapter_create_migrations_table_sql())
  Logger.log("Created table $(Genie.config.db_migrations_table_name) or table already exists")
end

function query(sql::AbstractString; system_query::Bool = false)
  suppress_output = system_query || Genie.config.suppress_output
  conn, adapter = query_tools()
  DatabaseAdapter.adapter_query(sql, suppress_output, conn, adapter)
end

@memoize function escape_column_name(c::AbstractString)
  conn, adapter = query_tools()
  DatabaseAdapter.adapter_escape_column_name(c, conn, adapter)
end

@memoize function escape_value(v::Union{AbstractString, Real})
  conn, adapter = query_tools()
  adapter.escapeliteral(conn, v)
end

@memoize function table_columns(table_name::AbstractString)
  conn, adapter = query_tools()
  query_df(DatabaseAdapter.adapter_table_columns_sql(table_name), suppress_output = true)
end

function query_df(sql::AbstractString; suppress_output::Bool = false)
  conn, adapter = query_tools()
  DatabaseAdapter.adapter_query_df(sql, (suppress_output || Genie.config.suppress_output), conn, adapter)
end

function relation_to_sql{T<:AbstractModel}(m::T, rel::Tuple{SQLRelation,Symbol})
  DatabaseAdapter.relation_to_sql(m, rel)
end

function to_fetch_sql{T<:AbstractModel, N<:AbstractModel}(m::Type{T}, q::SQLQuery, joins::Vector{SQLJoin{N}})
  DatabaseAdapter.to_fetch_sql(m, q, joins)
end
function to_fetch_sql{T<:AbstractModel}(m::Type{T}, q::SQLQuery)
  DatabaseAdapter.to_fetch_sql(m, q)
end

function to_store_sql{T<:AbstractModel}(m::T; conflict_strategy = :error) # upsert strateygy = :none | :error | :ignore | :update
  DatabaseAdapter.to_store_sql(m, conflict_strategy = conflict_strategy)
end

function delete_all{T<:AbstractModel}(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false)
  DatabaseAdapter.delete_all(m, truncate = truncate, reset_sequence = reset_sequence, cascade = cascade)
end

function delete{T<:AbstractModel}(m::T)
  DatabaseAdapter.delete(m)
end

function count{T<:AbstractModel}(m::Type{T}, q::SQLQuery = SQLQuery())
  DatabaseAdapter.count(m, q)
end

function update_query_part{T<:AbstractModel}(m::T)
  DatabaseAdapter.update_query_part(m)
end

function to_select_part{T<:AbstractModel}(m::Type{T}, cols::Vector{SQLColumn}, joins = SQLJoin[])
  DatabaseAdapter.to_select_part(m, cols, joins)
end

function to_from_part{T<:AbstractModel}(m::Type{T})
  DatabaseAdapter.to_from_part(m)
end

function to_where_part{T<:AbstractModel}(m::Type{T}, w::Vector{SQLWhere})
  DatabaseAdapter.to_where_part(m, w)
end

function to_order_part{T<:AbstractModel}(m::Type{T}, o::Vector{SQLOrder})
  DatabaseAdapter.to_order_part(m, o)
end

function to_group_part(g::Vector{SQLColumn})
  DatabaseAdapter.to_group_part(g)
end

function to_limit_part(l::SQLLimit)
  DatabaseAdapter.to_limit_part(l)
end

function to_offset_part(o::Int)
  DatabaseAdapter.to_offset_part(o)
end

function to_having_part(h::Vector{SQLHaving})
  DatabaseAdapter.to_having_part(h)
end

function to_join_part{T<:AbstractModel}(m::Type{T}, joins = SQLJoin[])
  DatabaseAdapter.to_join_part(m, joins)
end

end