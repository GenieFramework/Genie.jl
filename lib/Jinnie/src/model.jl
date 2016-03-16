module Model

using Database
using DataFrames
using Jinnie

include(abspath(joinpath("lib", "Jinnie", "src", "model_types.jl")))

#
# ORM methods
# 

function find_df{T<:JinnieModel}(m::Type{T}, q::SQLQuery)
  query(to_fetch_sql(m, prepare(m, q)))
end

function find{T<:JinnieModel}(m::Type{T}, q::SQLQuery)
  to_models(m, find_df(m, q))
end
function find{T<:JinnieModel}(m::Type{T})
  find(m, SQLQuery())
end

function find_by{T<:JinnieModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput)
  find(m, SQLQuery(where = [SQLWhere(column_name, value)]))
end
function find_by{T<:JinnieModel}(m::Type{T}, column_name::Any, value::Any)
  find_by(m, SQLColumn(column_name), SQLInput(value))
end

function find_one_by{T<:JinnieModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput)
  to_nullable(find_by(m, column_name, value))
end
function find_one_by{T<:JinnieModel}(m::Type{T}, column_name::Any, value::Any)
  find_one_by(m, SQLColumn(column_name), SQLInput(value))
end

function find_one{T<:JinnieModel}(m::Type{T}, value::Any)
  _m = disposable_instance(m)
  find_one_by(m, SQLColumn(_m._id), SQLInput(value))
end

function rand{T<:JinnieModel}(m::Type{T}; limit = 1)
  find(m, SQLQuery(limit = SQLLimit(limit), order = [SQLOrder("random()", raw = true)]) )
end

function rand_one{T<:JinnieModel}(m::Type{T})
  to_nullable(rand(m, limit = 1))
end

function all{T<:JinnieModel}(m::Type{T})
  find(m)
end

function save{T<:JinnieModel}(m::T; conflict_strategy = :error)
  try 
    save!(m, conflict_strategy)
    true
  catch 
    false
  end
end

function save!{T<:JinnieModel}(m::T; conflict_strategy = :error)
  sql = to_store_sql(m, conflict_strategy = conflict_strategy)
  to_models(typeof(m), query(sql)) |> first
end

#
# Object generation 
# 

function to_models(m, df::DataFrames.DataFrame)
  models = []
  for row in eachrow(df)
    push!(models, to_model(m, row))
  end

  return models
end

function to_model{T<:JinnieModel}(m::Type{T}, row::DataFrames.DataFrameRow)
   _m = disposable_instance(m) 
  obj = m()
  sf = settable_fields(_m, row)

  for field in sf
    value = try 
      Base.get(_m.on_hydration)(_m, field, row[field])
    catch 
      row[field]
    end

    field = from_fully_qualified(_m, field)
    setfield!(obj, field, convert(typeof(getfield(_m, field)), value))
  end

  obj    
end

# 
# Query generation
# 

function to_fetch_sql{T<:JinnieModel}(m::Type{T}, parts::Dict)
  _m = disposable_instance(m)
  """SELECT $(parts[:columns_part]) FROM $(_m._table_name) WHERE $(parts[:where_part]) $(parts[:group_part]) ORDER BY $(parts[:order_part]) LIMIT $(parts[:limit].value) OFFSET $(parts[:offset])"""
end

function to_store_sql{T<:JinnieModel}(m::T; conflict_strategy = :error) # upsert strateygy = :none | :error | :ignore | :update
  uf = persistable_fields(m)

  sql = if ! persisted(m) || (persisted(m) && conflict_strategy == :update)
    pos = findfirst(uf, m._id) 
    pos > 0 && splice!(uf, pos)

    fields = SQLColumn(uf)
    values = join( map(x -> string(prepare_for_db_save(m, symbol(x), getfield(m, symbol(x)))), uf), ", ")

    "INSERT INTO $(m._table_name) ( $fields ) VALUES ( $values )" * 
        if ( conflict_strategy == :error ) "" 
        elseif ( conflict_strategy == :ignore ) " ON CONFLICT DO NOTHING"
        elseif ( conflict_strategy == :update && !id_is_null ) 
           " ON CONFLICT ($(m._id)) DO UPDATE SET $(update_query_part(m))"
        else ""
        end
  else 
    "UPDATE $(m._table_name) SET $(update_query_part(m))"
  end 

  return sql * " RETURNING *"
end

function update_query_part{T<:JinnieModel}(m::T)
  update_values = join(map(x -> "$(string(SQLColumn(x))) = $( string(prepare_for_db_save(m, symbol(x), getfield(m, symbol(x)))) )", 
                            persistable_fields(m)), ", ")
  return " $update_values WHERE $(m._table_name).$(m._id) = '$(get(m.id))'"
end

function prepare_for_db_save{T<:JinnieModel}(m::T, field::Symbol, value)
  value = try 
            Base.get(m.on_dehydration)(m, field, value)
          catch 
            value
          end

  SQLInput(value)
end

# 
# delete methods 
# 

function delete_all{T<:JinnieModel}(m::Type{T}; truncate = true, reset_sequence = true, cascade = false)
  _m = disposable_instance(m)
  if truncate 
    sql = "TRUNCATE $(_m._table_name)"
    reset_sequence ? sql * " RESTART IDENTITY" : ""
    cascade ? sql * " CASCADE" : ""
  else 
    sql = "DELETE FROM $(_m._table_name)"
  end

  query(sql)
end

function delete{T<:JinnieModel}(m::T)
  sql = "DELETE FROM $(m._table_name) WHERE $(m._id) = '$(m.id)'"
  query(sql)
  
  tmp = typeof(m)()
  m.id = tmp.id
  return m
end

# 
# query execution
# 

function query(sql::AbstractString)
  query_df(sql)
end

function query_df(sql::AbstractString; supress_output = false) 
  supress_output = supress_output || config.supress_output
  conn, adapter = Database.query_tools()
  stmt = adapter.prepare(conn, sql)

  result = if supress_output
    adapter.execute(stmt)
  else 
    Jinnie.log("SQL QUERY: $(escape_string(sql))")
    @run_with_time adapter.execute(stmt)
  end

  if ( adapter.errstring(result) != "" )
    error("$(string(adapter)) error: $(adapter.errstring(result)) [$(adapter.errcode(result))]")
  end

  df = adapter.fetchdf(result)
  adapter.finish(stmt)

  @unless(supress_output, Jinnie.log(df))

  return df
end

# 
# ORM utils
# 

function is_subtype{T<:JinnieModel}(m::Type{T}, parent_model = JinnieModel)
  return m <: parent_model
end

function disposable_instance{T<:JinnieModel}(m::Type{T})
  if is_subtype(m)
    return m()
  else 
    error("$m is not a Model")
  end
end

function prepare{T<:JinnieModel}(m::Type{T}, q::SQLQuery)
  _m = disposable_instance(m)

  columns_part =  if ( length(q.columns) > 0 ) string(q.columns)
                  else join(to_fully_qualified_sql_column_names(_m, persistable_fields(_m)), ", ")
                  end

  where_part =    if ( length(q.where) == 0 ) "TRUE"
                  else (q.where[1].condition.value == "AND" ? "TRUE " : "FALSE ") * join(map(w -> string(w), q.where), " ")
                  end

  order_part =    if ( length(q.order) == 0 ) to_sql_column_name(_m, _m._id)
                  else join(map(x -> "$(x.column) $(x.direction)", q.order), ", ")
                  end

  group_part =    if ( length(q.group) > 0 ) " GROUP BY " * join(map(x -> safe(x.value), q.group), ", ")
                  else ""
                  end

  having_part =   if ( length(q.having) == 0 ) "TRUE"
                  else (q.having[1].condition.value == "AND" ? "TRUE " : "FALSE ") * join(map(w -> string(w), q.having), " ")
                  end

  Dict(:columns_part => columns_part, :where_part => where_part, :order_part => order_part, :group_part => group_part, :limit => q.limit, :offset => q.offset, :having_part => having_part)
end

@memoize function columns(m)
  _m = disposable_instance(m)
  conn, adapter = Database.query_tools()
  if ( adapter != Database.POSTGRESQL_ADAPTER ) error("Not supported") end

  sql = "SELECT 
            column_name, ordinal_position, column_default, is_nullable, data_type, character_maximum_length, 
            udt_name, is_identity, is_updatable
          FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = '$(_m._table_name)'"

  query_df(sql, supress_output = true)
end

function persisted{T<:JinnieModel}(m::T)
  ! ( isa(getfield(m, symbol(m._id)), Nullable) && isnull( getfield(m, symbol(m._id)) ) )
end

function persistable_fields{T<:JinnieModel}(m::T; fully_qualified = false)
  object_fields = map(x -> string(x), fieldnames(m))
  db_columns = columns(typeof(m))[:column_name]
  persistable_fields = intersect(object_fields, db_columns)
  fully_qualified ? to_fully_qualified_sql_column_names(m, persistable_fields) : persistable_fields
end

function settable_fields{T<:JinnieModel}(m::T, row::DataFrames.DataFrameRow)
  df_cols = names(row)
  fields = is_fully_qualified(m, df_cols[1]) ? to_sql_column_names(m, fieldnames(m)) : fieldnames(m)
  intersect(fields, df_cols)
end

#
# Data sanitization 
# 

@memoize function to_sql(sql::AbstractString, params::Tuple)
  i = 0
  function splat_params(_) 
    i += 1
    Database.escape_value(params[i])
  end

  sql = replace(sql, '?', splat_params)
end
@memoize function to_sql(sql::AbstractString, params::Dict)
  function dict_params(key) 
    key = Symbol(replace(key, r"^:", ""))
    Database.escape_value(params[key])
  end

  replace(sql, r":([a-zA-Z0-9]*)", dict_params)
end

@memoize function escape_column_name(c::SQLColumn)
  if ! c.escaped && ! c.raw
    c.value = Database.escape_column_name(c.value)
    c.escaped = true
  end

  c
end

@memoize function escape_value(i::SQLInput)
  if ! i.escaped && ! i.raw
    i.value = Database.escape_value(i.value)
    i.escaped = true
  end

  return i
end

# 
# utility functions 
# 

function has_field{T<:JinnieModel}(m::T, f::Symbol)
  in(f, fieldnames(m))
end

function strip_table_name{T<:JinnieModel}(m::T, f::Symbol)
  replace(string(f), Regex("^$(m._table_name)_"), "", 1) |> Symbol
end

function is_fully_qualified{T<:JinnieModel}(m::T, f::Symbol)
  startswith(string(f), m._table_name) && has_field(m, strip_table_name(m, f))
end

function from_fully_qualified{T<:JinnieModel}(m::T, f::Symbol)
  is_fully_qualified(m, f) ? strip_table_name(m, f) : f
end

function to_fully_qualified{T<:JinnieModel}(m::T, f::AbstractString)
  "$(m._table_name).$f"
end

function  to_sql_column_names{T<:JinnieModel}(m::T, fields::Array{Symbol, 1})
  map(x -> (to_sql_column_name(m, string(x))) |> Symbol, fields)
end

function to_sql_column_name{T<:JinnieModel}(m::T, f::AbstractString)
  "$(m._table_name)_$f"
end

function to_fully_qualified_sql_column_names{T<:JinnieModel, S<:AbstractString}(m::T, persistable_fields::Array{S, 1})
  map(x -> to_fully_qualified_sql_column_name(m, x), persistable_fields)
end

function to_fully_qualified_sql_column_name{T<:JinnieModel}(m::T, f::AbstractString)
  "$(to_fully_qualified(m, f)) AS $(to_sql_column_name(m, f))"
end

function to_dict{T<:JinnieModel}(m::T; all_fields = false) 
  fields = all_fields ? fieldnames(m) : persistable_fields(m)
  [string(f) => getfield(m, Symbol(f)) for f in fields]
end
function to_dict{T<:JinnieType}(m::T) 
  Jinnie.to_dict(m)
end

function to_string_dict{T<:JinnieModel}(m::T; all_fields = false) 
  fields = all_fields ? fieldnames(m) : persistable_fields(m)
  [string(f) => string(getfield(m, Symbol(f))) for f in fields]
end
function to_string_dict{T<:JinnieType}(m::T) 
  Jinnie.to_string_dict(m)
end

function to_nullable(result)
  isempty(result) ? Nullable{JinnieModel}() : Nullable{JinnieModel}(result |> first)
end

function escape_type(value)
  return if isa(value, AbstractString)
    value = replace(value, "\$", "\\\$")
    value = replace(value, "\@", "\\\@")
    "\"$value\""
  elseif isa(value, Char)
    "'$value'"
  else 
    value
  end
end

end

M = Model