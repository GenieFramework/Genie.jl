using Database
using DataFrames
using Memoize

abstract Jinnie_Model

function find(m::Jinnie_Model; where = "TRUE", limit = "ALL", offset = "0", order = m._id, group = "", having = "")
  sql = """SELECT * FROM $(m._table_name) WHERE $where ORDER BY $order LIMIT $limit OFFSET $offset"""

  return run_query_df(sql)
end

function df_to_m(df::DataFrames.DataFrame, m)
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

function all(m::Jinnie_Model)
  sql = "SELECT * FROM $(m._table_name)"

  return run_query_df(sql)
end

function save!(m::Jinnie_Model; upsert_strategy = :error)
  sql = build_insert_sql(m, upsert_strategy = upsert_strategy)

  return run_query_df(sql)
end

@memoize function columns(m::Jinnie_Model)
  conn, adapter = Database.query_tools()
  if ( adapter != Database.POSTGRESQL_ADAPTER ) error("Not supported") end

  sql = "SELECT 
            column_name, ordinal_position, column_default, is_nullable, data_type, character_maximum_length, 
            udt_name, is_identity, is_updatable
          FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = '$(m._table_name)'"

  return run_query_df(sql)
end

function build_insert_sql(m::Jinnie_Model; upsert_strategy = :error)
  object_fields = map(x -> string(x), fieldnames(m))
  db_columns = columns(m)[:column_name]
  updatable_fields = intersect(object_fields, db_columns)

  fields = join(updatable_fields, ", ")
  values = join( map(x -> Util.add_sql_quotes(escape_string(getfield(m, symbol(x)))), updatable_fields), ", " )

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
  result = adapter.execute(stmt)

  if ( adapter.errstring(result) != "" )
    error("$(string(adapter)) error: $(adapter.errstring(result)) [$(adapter.errcode(result))]")
  end

  df = adapter.fetchdf(result)
  adapter.finish(stmt)

  return df
end