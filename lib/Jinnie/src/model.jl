abstract Jinnie_Model

module Model

using Jinnie
using Database
using DataFrames
using Memoize

function find(m::Jinnie.Jinnie_Model; columns = "*", where = "TRUE", limit = "ALL", offset = "0", order = m._id, group = "", having = "")
  sql = """SELECT $columns FROM $(m._table_name) WHERE $where ORDER BY $order LIMIT $limit OFFSET $offset"""

  return run_query_df(sql)
end

function find_by{T<:Jinnie.Jinnie_Model}(m::T, column_name, value)
  return find(m(), where = "$column_name = $value")
end

function df_to_m{T<:Jinnie.Jinnie_Model}(df::DataFrames.DataFrame, m::T) 
  models = []
  fields = fieldnames(m)
  df_cols = names(df)
  settable_fields = intersect(fields, df_cols)
  for row = eachrow(df)
    params = []
    for field = settable_fields
      push!(params, "$(string(field)) = \"$(row[field])\"")
    end
    obj = eval(parse("""$(typeof(m))(; $(join(params, ",")) )"""))
    push!(models, obj)
  end

  return models
end

function dfrow_to_m{T<:Jinnie.Jinnie_Model}(dfrow::DataFrames.DataFrameRow, m::T) 
  fields = fieldnames(m)
  df_cols = names(dfrow)
  settable_fields = intersect(fields, df_cols)
  
  params = []
  for field = settable_fields
    push!(params, "$(string(field)) = \"$(dfrow[field])\"")
  end
  
  return eval(parse("""$(typeof(m))(; $(join(params, ",")) )"""))
end

function all(m::Jinnie.Jinnie_Model)
  sql = "SELECT * FROM $(m._table_name)"

  return run_query_df(sql)
end

function save!(m::Jinnie.Jinnie_Model; upsert_strategy = :error)
  sql = build_insert_sql(m, upsert_strategy = upsert_strategy)

  return run_query_df(sql)
end

@memoize function columns(m::Jinnie.Jinnie_Model)
  conn, adapter = Database.query_tools()
  if ( adapter != Database.POSTGRESQL_ADAPTER ) error("Not supported") end

  sql = "SELECT 
            column_name, ordinal_position, column_default, is_nullable, data_type, character_maximum_length, 
            udt_name, is_identity, is_updatable
          FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = '$(m._table_name)'"

  return run_query_df(sql)
end

function build_insert_sql(m::Jinnie.Jinnie_Model; upsert_strategy = :error)
  object_fields = map(x -> string(x), fieldnames(m))
  db_columns = columns(m)[:column_name]
  updatable_fields = intersect(object_fields, db_columns)

  if ( getfield(m, symbol(m._id)) == m._id_unset_value ) # id not set, allow auto-increment query
    pos = findfirst(updatable_fields, m._id)
    splice!(updatable_fields, pos)
  end

  fields = join(updatable_fields, ", ")
  values = join( map(x -> isa(getfield(m, symbol(x)), AbstractString) ? Jinnie.Util.add_sql_quotes(escape_string(string(getfield(m, symbol(x))))) : getfield(m, symbol(x)), updatable_fields), ", " )

  sql = "INSERT INTO $(m._table_name) ( $fields ) VALUES ( $values )"

  return sql *  if ( upsert_strategy == :error ) "" 
                elseif ( upsert_strategy == :nothing ) " ON CONFLICT DO NOTHING"
                elseif ( upsert_strategy == :update ) 
                  #update_values = join( map(x -> "$x = $( Util.add_sql_quotes(escape_string(getfield(m, symbol(x)))) )", updatable_fields), ", " )
                  #" DO UPDATE SET $update_values"
                  error("Not implemented")
                  ""
                end
end

function run_query_df(sql)
  conn, adapter = Database.query_tools()
  stmt = adapter.prepare(conn, sql)

  Jinnie.log("SQL QUERY: $sql")

  result = adapter.execute(stmt)

  if ( adapter.errstring(result) != "" )
    error("$(string(adapter)) error: $(adapter.errstring(result)) [$(adapter.errcode(result))]")
  end

  df = adapter.fetchdf(result)
  adapter.finish(stmt)

  return df
end

end