module PostgreSQLDatabaseAdapter
using PostgreSQL, DataFrames, Genie, Database, Logger, SearchLight, Util

export adapter_connect, db_adapter, adapter_table_columns_sql, create_migrations_table_sql, adapter_escape_column_name
export adapter_query_df, adapter_query

const DEFAULT_PORT = 5432

function adapter_connect(conn_data::Dict{String,Any})
  try
    connect(Postgres,
            conn_data["host"],
            conn_data["username"],
            conn_data["password"],
            conn_data["database"],
            conn_data["port"])
  catch ex
    Logger.log("Invalid DB connection settings", :err)
    Logger.@location()
    Logger.log(ex, :err)
  end
end

function adapter_table_columns_sql(table_name::AbstractString) :: String
  "SELECT
    column_name, ordinal_position, column_default, is_nullable, data_type, character_maximum_length,
    udt_name, is_identity, is_updatable
  FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = '$table_name'"
end

function adapter_create_migrations_table_sql()
  "CREATE TABLE $(Genie.config.db_migrations_table_name) (version varchar(30) CONSTRAINT firstkey PRIMARY KEY)"
end

function adapter_escape_column_name(c::AbstractString, conn, adapter) :: String
  strptr = adapter.PQescapeIdentifier(conn.ptr, c, sizeof(c))
  str = unsafe_string(strptr)
  adapter.PQfreemem(strptr)

  str
end

function adapter_query_df(sql::AbstractString, suppress_output::Bool, conn, adapter) :: DataFrames.DataFrame
  df::DataFrames.DataFrame = adapter.fetchdf(adapter_query(sql, suppress_output, conn, adapter))
  (! suppress_output && Genie.config.log_db) && Logger.log(df)

  df
end

function adapter_query(sql::AbstractString, suppress_output::Bool, conn, adapter)
  stmt = adapter.prepare(conn, sql)

  result = if suppress_output || ( ! Genie.config.log_db && ! Genie.config.log_queries )
    adapter.execute(stmt)
  else
    Logger.log("SQL QUERY: $(escape_string(sql))")
    @time adapter.execute(stmt)
  end
  adapter.finish(stmt)

  if ( adapter.errstring(result) != "" )
    error("$(string(adapter)) error: $(adapter.errstring(result)) [$(adapter.errcode(result))]")
  end

  result
end

function db_adapter()
  PostgreSQL
end

function relation_to_sql{T<:AbstractModel}(m::T, rel::Tuple{SQLRelation,Symbol})
  rel, rel_type = rel
  j = disposable_instance(rel.model_name)
  join_table_name = j._table_name

  if rel_type == RELATION_BELONGS_TO
    j, m = m, j
  end

  (join_table_name |> escape_column_name) * " ON " *
    (j._table_name |> escape_column_name) * "." *
    ( (lowercase(string(typeof(m))) |> SearchLight.strip_module_name) * "_" * m._id |> escape_column_name) *
    " = " *
    (m._table_name |> escape_column_name) * "." *
    (m._id |> escape_column_name)
end

function to_find_sql{T<:AbstractModel, N<:AbstractModel}(m::Type{T}, q::SQLQuery, joins::Vector{SQLJoin{N}})
  sql::String = ( "$(to_select_part(m, q.columns, joins)) $(to_from_part(m)) $(to_join_part(m, joins)) $(to_where_part(m, q.where, q.scopes)) " *
                      "$(to_group_part(q.group)) $(to_order_part(m, q.order)) " *
                      "$(to_having_part(q.having)) $(to_limit_part(q.limit)) $(to_offset_part(q.offset))") |> strip
  replace(sql, r"\s+", " ")
end
function to_find_sql{T<:AbstractModel}(m::Type{T}, q::SQLQuery)
  sql::String = ( "$(to_select_part(m, q.columns)) $(to_from_part(m)) $(to_join_part(m)) $(to_where_part(m, q.where, q.scopes)) " *
                      "$(to_group_part(q.group)) $(to_order_part(m, q.order)) " *
                      "$(to_having_part(q.having)) $(to_limit_part(q.limit)) $(to_offset_part(q.offset))") |> strip
  replace(sql, r"\s+", " ")
end
const to_fetch_sql = to_find_sql

function to_store_sql{T<:AbstractModel}(m::T; conflict_strategy = :error) # upsert strateygy = :none | :error | :ignore | :update
  uf = persistable_fields(m)

  sql = if ! is_persisted(m) || (is_persisted(m) && conflict_strategy == :update)
    pos = findfirst(uf, m._id)
    pos > 0 && splice!(uf, pos)

    fields = SQLColumn(uf)
    vals = join( map(x -> string(to_sqlinput(m, Symbol(x), getfield(m, Symbol(x)))), uf), ", ")

    "INSERT INTO $(m._table_name) ( $fields ) VALUES ( $vals )" *
        if ( conflict_strategy == :error ) ""
        elseif ( conflict_strategy == :ignore ) " ON CONFLICT DO NOTHING"
        elseif ( conflict_strategy == :update && ! isnull( getfield(m, Symbol(m._id)) ) )
           " ON CONFLICT ($(m._id)) DO UPDATE SET $(update_query_part(m))"
        else ""
        end
  else
    "UPDATE $(m._table_name) SET $(update_query_part(m))"
  end

  return sql * " RETURNING $(m._id)"
end

function delete_all{T<:AbstractModel}(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false) :: Void
  _m::T = m()
  if truncate
    sql = "TRUNCATE $(_m._table_name)"
    reset_sequence ? sql * " RESTART IDENTITY" : ""
    cascade ? sql * " CASCADE" : ""
  else
    sql = "DELETE FROM $(_m._table_name)"
  end

  SearchLight.query(sql)

  nothing
end

function delete{T<:AbstractModel}(m::T) :: T
  sql = "DELETE FROM $(m._table_name) WHERE $(m._id) = '$(m.id |> Base.get)'"
  SearchLight.query(sql)

  tmp::T = T()
  m.id = tmp.id

  m
end

function count{T<:AbstractModel}(m::Type{T}, q::SQLQuery = SQLQuery()) :: Int
  count_column = SQLColumn("COUNT(*) AS __cid", raw = true)
  q = SearchLight.clone(q, :columns, push!(q.columns, count_column))

  find_df(m, q)[1, Symbol("__cid")]
end

function update_query_part{T<:AbstractModel}(m::T)
  update_values = join(map(x -> "$(string(SQLColumn(x))) = $( string(to_sqlinput(m, Symbol(x), getfield(m, Symbol(x)))) )", persistable_fields(m)), ", ")
  return " $update_values WHERE $(m._table_name).$(m._id) = '$(Base.get(m.id))'"
end

function to_select_part{T<:AbstractModel}(m::Type{T}, cols::Vector{SQLColumn}, joins = SQLJoin[])
  _m::T = m()

  function columns_from_joins()
    jcols = []
    for j in joins
      jcols = vcat(jcols, j.columns)
    end

    jcols
  end

  function prepare_column_name(column::SQLColumn)
    if column.raw
      column.value
    else
      column_data = SearchLight.from_literal_column_name(column.value)
      if ! haskey(column_data, :table_name)
        column_data[:table_name] = _m._table_name
      end
      if ! haskey(column_data, :alias)
        column_data[:alias] = ""
      end

      "$(to_fully_qualified(column_data[:column_name], column_data[:table_name])) AS $( isempty(column_data[:alias]) ? SearchLight.to_sql_column_name(column_data[:column_name], column_data[:table_name]) : column_data[:alias] )"
    end
  end

  function _to_select_part()
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
      table_columns = isempty(table_columns) ? AbstractString[] : vcat(table_columns, map(x -> prepare_column_name(x), columns_from_joins()))

      related_table_columns = String[]
      for rels in map(x -> to_fully_qualified_sql_column_names(x, persistable_fields(x), escape_columns = true), joined_tables)
        for col in rels
          push!(related_table_columns, col)
        end
      end

      return join([table_columns ; related_table_columns], ", ")
    end
  end

  "SELECT " * _to_select_part()
end

function to_from_part{T<:AbstractModel}(m::Type{T})
  "FROM " * escape_column_name(disposable_instance(m)._table_name)
end

function to_where_part{T<:AbstractModel}(m::Type{T}, w::Vector{SQLWhereEntity}, scopes::Vector{Symbol}) :: String
  w = vcat(w, required_scopes(m)) # automatically include required scopes

  _m::T = m()
  for scope in scopes
    w = vcat(w, _m.scopes[scope])
  end

  to_where_part(w)
end
function to_where_part(w::Vector{SQLWhereEntity}) :: String
  where = isempty(w) ?
          "" :
          "WHERE " * (string(first(w).condition) == "AND" ? "TRUE " : "FALSE ") * join(map(wx -> string(wx), w), " ")

  replace(where, r"WHERE TRUE AND "i, "WHERE ")
end

function required_scopes{T<:AbstractModel}(m::Type{T}) :: Vector{SQLWhereEntity}
  s = scopes(m)
  haskey(s, :required) ? s[:required] : SQLWhereEntity[]
end

function scopes{T<:AbstractModel}(m::Type{T}) :: Dict{Symbol,Vector{SQLWhereEntity}}
  in(:scopes, fieldnames(m)) ? getfield(m()::T, :scopes) :  Dict{Symbol,Vector{SQLWhereEntity}}()
end

function to_order_part{T<:AbstractModel}(m::Type{T}, o::Vector{SQLOrder}) :: String
  isempty(o) ?
    "" :
    "ORDER BY " * join(map(x -> (! is_fully_qualified(x.column.value) ? to_fully_qualified(m, x.column) : x.column.value) * " " * x.direction, o), ", ")
end

function to_group_part(g::Vector{SQLColumn}) :: String
  isempty(g) ?
    "" :
    " GROUP BY " * join(map(x -> string(x), g), ", ")
end

function to_limit_part(l::SQLLimit) :: String
  l.value != "ALL" ? "LIMIT " * (l |> string) : ""
end

function to_offset_part(o::Int) :: String
  o != 0 ? "OFFSET " * (o |> string) : ""
end

function to_having_part(h::Vector{SQLWhereEntity}) :: String
  having =  isempty(h) ?
            "" :
            "HAVING " * (string(first(h).condition) == "AND" ? "TRUE " : "FALSE ") * join(map(w -> string(w), h), " ")

  replace(having, r"HAVING TRUE AND "i, "HAVING ")
end

function to_join_part{T<:AbstractModel}(m::Type{T}, joins = SQLJoin[]) :: String
  _m = m()
  join_part = ""

  for rel in relations(m)
    mr = first(rel)
    if ( mr |> is_lazy ) continue end
    if ! isnull(mr.join)
      join_part *= mr.join |> Base.get |> string
    else # default
      join_part *= (mr.required ? "INNER " : "LEFT ") * "JOIN " * relation_to_sql(_m, rel)
    end
  end

  join_part * join( map(x -> string(x), joins), " " )
end

end
