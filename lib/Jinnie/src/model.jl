abstract Jinnie_Model
DbId = Union{Int32, Int64, Nullable{Int32}, Nullable{Int64}}

module Model

using Jinnie
using Database
using DataFrames
using Memoize
using JSON

@memoize function is_subtype(m, parent_model = Jinnie.Jinnie_Model)
  return m <: parent_model
end

@memoize function disposable_instance(m)
  if is_subtype(m)
    return m()
  else 
    error("$m is not a Model")
  end
end

function find(m; columns = "*", where = "TRUE", limit = "ALL", offset = "0", order = "", group = "", having = "")
  _m = disposable_instance(m)
  order == "" ? order = _m._id : ""
  sql = """SELECT $columns FROM $(_m._table_name) WHERE $where ORDER BY $order LIMIT $limit OFFSET $offset"""

  return df_to_m(run_query_df(sql), m)
end

function find_by(m, column_name::Symbol, value)
  find_by(m, string(column_name), value)
end

function find_by(m, column_name::AbstractString, value)
  return find(m, where = "$column_name = $value")
end

function rand(m)
  df = find(m, limit = "1", order = "random()")
  return ( df |> first )
end

function df_to_m(df::DataFrames.DataFrame, m)
  _m = disposable_instance(m) 
  models = []
  fields = fieldnames(_m)
  df_cols = names(df)
  settable_fields = intersect(fields, df_cols)

  for row = eachrow(df)
    params = []
    for field = settable_fields
      value = row[field]
      value = try 
        Base.get(_m.on_hydration)(_m, field, value)
      catch 
        Jinnie.log("MODEL: can not hydrate $(typeof(_m)) on field $field for value $value", :error)
        value
      end

      if isa(value, AbstractString)
        push!(params, """$(string(field)) = "$value" """)
      else 
        push!(params, "$(string(field)) = $value")
      end
    end

    obj = eval(parse("""$m(; $(join(params, ",")) )"""))
    push!(models, obj)
  end

  return models
end

function dfrow_to_m(dfrow::DataFrames.DataFrameRow, m) 
  _m = disposable_instance(m)
  fields = fieldnames(_m)
  df_cols = names(dfrow)
  settable_fields = intersect(fields, df_cols)
  
  params = []
  for field = settable_fields
    value = dfrow[field]
    value = try 
      Base.get(_m.on_hydration)(_m, field, value)
    catch 
      Jinnie.log("MODEL: can not hydrate $(typeof(_m)) on field $field for value $value", :error)
      value
    end

    if isa(value, AbstractString)
      push!(params, """$(string(field)) = "$value" """)
    else 
      push!(params, "$(string(field)) = $value")
    end
  end
  
  return eval(parse("""$m(; $(join(params, ",")) )"""))
end

function all(m)
  find(m)
end

function save{T<:Jinnie.Jinnie_Model}(m::T; upsert_strategy = :none)
  sql = build_save_sql(m, upsert_strategy = upsert_strategy)
  result = run_query_df(sql)
  setfield!(m, symbol(m._id), first(result[symbol(m._id)]))
  true
end

@memoize function columns(m)
  _m = disposable_instance(m)
  conn, adapter = Database.query_tools()
  if ( adapter != Database.POSTGRESQL_ADAPTER ) error("Not supported") end

  sql = "SELECT 
            column_name, ordinal_position, column_default, is_nullable, data_type, character_maximum_length, 
            udt_name, is_identity, is_updatable
          FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = '$(_m._table_name)'"

  return run_query_df(sql)
end

@memoize function updatable_fields(m::Jinnie.Jinnie_Model)
  object_fields = map(x -> string(x), fieldnames(m))
  db_columns = columns(typeof(m))[:column_name]
  return intersect(object_fields, db_columns)
end

function build_save_sql(m::Jinnie.Jinnie_Model; upsert_strategy = :none) # upsert strateygy = :none | :error | :ignore | :update
  uf = updatable_fields(m)

  if isa(getfield(m, symbol(m._id)), Nullable) && isnull( getfield(m, symbol(m._id)) ) # id not set, allow auto-increment query
    pos = findfirst(uf, m._id)
    splice!(uf, pos)
  elseif upsert_strategy == :none # id set and no upsert strategy, do a plain update
    sql = "UPDATE $(m._table_name) SET $(update_query_part(m))"
  end 

  if upsert_strategy != :none  # upsert strategy set, do insert ... on conflict ...
    fields = join(uf, ", ")
    values = join( map(x -> prepare_for_db_save(m, symbol(x), getfield(m, symbol(x))), uf), ", " )

    sql = "INSERT INTO $(m._table_name) ( $fields ) VALUES ( $values )"

    sql = sql *   if ( upsert_strategy == :error ) "" 
                  elseif ( upsert_strategy == :ignore ) " ON CONFLICT DO NOTHING"
                  elseif ( upsert_strategy == :update ) 
                    " ON CONFLICT ($(m._id)) DO UPDATE SET $(update_query_part(m))"
                  end
  end 

  return sql * " RETURNING $(m._id)"
end

function update_query_part(m::Jinnie.Jinnie_Model)
  update_values = join( map(x -> "$x = $( prepare_for_db_save(m, symbol(x), getfield(m, symbol(x))) )", updatable_fields(m)), ", " )
  return " $update_values WHERE $(m._table_name).$(m._id) = '$(m.id)'"
end

function prepare_for_db_save(m::Jinnie.Jinnie_Model, field::Symbol, value)
  value = try 
    Base.get(m.on_dehydration)(m, field, value)
  catch 
    Jinnie.log("MODEL: can not dehydrate $(typeof(m)) on field $field for value $value", :error)
    value
  end

  if isa(value, AbstractString) || isa(value, Char)
    value = Database.add_sql_quotes(escape_string(string(value)))
  end

  return value
end

function delete_all(m; truncate = true, reset_sequence = true, cascade = false)
  _m = disposable_instance(m)
  if truncate 
    sql = "TRUNCATE $(_m._table_name)"
    reset_sequence ? sql * " RESTART IDENTITY" : ""
    cascade ? sql * " CASCADE" : ""
  else 
    sql = "DELETE FROM $(_m._table_name)"
  end

  run_query_df(sql)
end

function delete{T<:Jinnie.Jinnie_Model}(m::T)
  sql = "DELETE FROM $(m._table_name) WHERE $(m._id) = '$(m.id)'"
  run_query_df(sql)
  
  tmp = typeof(m)()
  m.id = tmp.id
  return m
end

function run_query_df(sql)
  conn, adapter = Database.query_tools()
  stmt = adapter.prepare(conn, sql)

  Jinnie.log("SQL QUERY: $(escape_string(sql))")

  @run_with_time result = adapter.execute(stmt)

  if ( adapter.errstring(result) != "" )
    error("$(string(adapter)) error: $(adapter.errstring(result)) [$(adapter.errcode(result))]")
  end

  df = adapter.fetchdf(result)
  adapter.finish(stmt)

  return df
end

end