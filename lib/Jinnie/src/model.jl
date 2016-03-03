module Model

using Jinnie
using Database
using DataFrames
using Memoize
using JSON

import Base.string
import Base.print
import Base.show
import Base.convert
import Base.endof
import Base.length
import Base.next

abstract SQLType <: JinnieType

type SQLString <: AbstractString
  value::AbstractString
  SQLString(v::Any) = new(string(v))
end
string(s::SQLString) = safe(s.value)
endof(s::SQLString) = endof(s.value)
length(s::SQLString) = length(s.value)
next(s::SQLString, i::Int) = next(s.value, i)
safe(s::AbstractString) = Jinnie.Database.add_sql_quotes(s)
safe(s::SQLString) = safe(s.value)
safe(n::Real) = n

SQLInput = Union{SQLString, Real}
convert(::Type{SQLInput}, s::AbstractString) = SQLString(s)

type SQLColumn <: SQLType
  value::AbstractString
  SQLColumn(v::Symbol) = new(string(v))
end
function SQLColumn(v::AbstractString) 
  if contains(v, ",")
    return map(x -> SQLColumn(symbol(strip(x))), split(v, ","))
  else 
    return SQLColumn(symbol(strip(v)))
  end
end
string(a::Array{SQLColumn}) = join(map(x -> string(x), a), ",")
print(io::IO, a::Array{SQLColumn}) = print(io, string(a))
show(io::IO, a::Array{SQLColumn}) = print(io, string(a))
string(s::SQLColumn) = safe(s)
print(s::SQLColumn) = print(io, string(a))
show(s::SQLColumn) = print(io, string(a))
safe(s::SQLColumn) = Jinnie.Database.add_sql_quotes(s.value, "\"")

type SQLLogicOperator <: SQLType
  value::AbstractString
  SQLLogicOperator() = new("AND")
  SQLLogicOperator(v::AbstractString) = new(v)
  SQLLogicOperator(v::Any) = new( string(v) == "OR" ? SQLLogicOperator("OR") : SQLLogicOperator("AND") )
end
string(s::SQLLogicOperator) = s.value

type SQLWhere <: SQLType
  column::SQLColumn
  value::SQLInput
  condition::SQLLogicOperator
  operator::AbstractString

  SQLWhere(column::Any, value::Any, condition::Any, operator::Any) =  new(
                                                                        SQLColumn(string(column)), 
                                                                        SQLInput(value), 
                                                                        SQLLogicOperator(uppercase(string(condition))), 
                                                                        string(operator)
                                                                      )
end
SQLWhere(column::Any, value::Any, condition::Any) = SQLWhere(column, value, condition, "=")
SQLWhere(column::Any, value::Any) = SQLWhere(column, value, "AND")
string(w::SQLWhere) = "$(w.condition.value) ( $(string(w.column)) $(w.operator) ( $(w.value) ) )"
print{T<:SQLWhere}(io::IO, w::T) = print(io, "$(jinnietype_to_string(w)) \n $(string(w))")
show{T<:SQLWhere}(io::IO, w::T) = print(io, "$(jinnietype_to_string(w)) \n $(string(w))")

type SQLLimit <: SQLType
  value::Union{Int, AbstractString}
  SQLLimit(v::Int) = new(v)
  SQLLimit(v::AbstractString) = new("ALL")
  SQLLimit() = new("ALL")
end

type SQLFunction <: SQLType
  value::AbstractString
  SQLFunction(v::AbstractString) = endswith(v, "()") ? new(v) : error("Invalid SQL Function argument")
end

SQLIdentifier = Union{SQLColumn, SQLFunction}
DbId = Union{Int32, Int64, Nullable{Int32}, Nullable{Int64}}

type SQLOrder <: SQLType
  column::SQLIdentifier
  direction::AbstractString
  SQLOrder(column::Any, direction::Any) = new(  endswith(string(column), "()") ? SQLFunction(string(column)) : SQLColumn(string(column)), 
                                                uppercase(string(direction)) == "DESC" ? "DESC" : "ASC" )
end
SQLOrder(column::Any) = SQLOrder(column, "ASC")

@memoize function is_subtype(m, parent_model = JinnieModel)
  return m <: parent_model
end

@memoize function disposable_instance(m)
  if is_subtype(m)
    return m()
  else 
    error("$m is not a Model")
  end
end

function prepare(m; columns::Array{SQLColumn} = SQLColumn[], 
                    where::Array{SQLWhere} = SQLWhere[], 
                    limit::SQLLimit = SQLLimit("ALL"), 
                    offset::Int = 0, 
                    order::Array{SQLOrder} = SQLOrder[], 
                    group::Array{SQLColumn} = SQLColumn[], 
                    all_columns = false)
  _m = disposable_instance(m)

  columns_part =  if all_columns "*"
                  elseif ( length(columns) > 0 ) string(columns)
                  else join(updatable_fields(_m), ", ")
                  end

  where_part =    if ( length(where) == 0 ) "TRUE"
                  else (where[1].condition.value == "AND" ? "TRUE " : "FALSE ") * join(map(w -> string(w), where), " ")
                  end

  order_part =    if ( length(order) == 0 ) _m._id
                  else join(map(x -> "$(x.column.value) $(x.direction)", order), ", ")
                  end

  group_part =    if ( length(group) > 0 ) " GROUP BY " * join(map(x -> safe(x.value), group), ", ")
                  else ""
                  end

  return Dict(:columns_part => columns_part, :where_part => where_part, :order_part => order_part, :group_part => group_part, :limit => limit, :offset => offset)
end

function prepare_sql(m, parts::Dict)
  _m = disposable_instance(m)
  """SELECT $(parts[:columns_part]) FROM $(_m._table_name) WHERE $(parts[:where_part]) $(parts[:group_part]) ORDER BY $(parts[:order_part]) LIMIT $(parts[:limit].value) OFFSET $(parts[:offset])"""
end

function find_df(m;   columns::Array{SQLColumn} = SQLColumn[], 
                      where::Array{SQLWhere} = SQLWhere[], 
                      limit::SQLLimit = SQLLimit("ALL"), 
                      offset::Int = 0, 
                      order::Array{SQLOrder} = SQLOrder[], 
                      group::Array{SQLColumn} = SQLColumn[], 
                      all_columns = false)

  return run_query_df(prepare_sql(m, prepare(m, columns = columns, where = where, limit = limit, offset = offset, order = order, group = group, all_columns = all_columns)))
end

function find(m;      columns::Array{SQLColumn} = SQLColumn[], 
                      where::Array{SQLWhere} = SQLWhere[], 
                      limit::SQLLimit = SQLLimit("ALL"), 
                      offset::Int = 0, 
                      order::Array{SQLOrder} = SQLOrder[], 
                      group::Array{SQLColumn} = SQLColumn[], 
                      all_columns = false)

  return df_to_m(find_df(m, columns = columns, where = where, limit = limit, offset = offset, order = order, group = group, all_columns = all_columns), m)
end

function find_unsafe(m;  columns = "*", where = "TRUE", limit = "ALL", offset = "0", order = "", group = "", having = "", 
                  return_df = false, all_columns = false)
  _m = disposable_instance(m)
  order == "" ? order = _m._id : ""
  columns = all_columns ? "*" : join(updatable_fields(_m), ", ")
  sql = """SELECT $columns FROM $(_m._table_name) WHERE $where ORDER BY $order LIMIT $limit OFFSET $offset"""

  df = run_query_df(sql)
  return return_df ? df : df_to_m(df, m)
end

function find_by(m, column_name::Symbol, value::SQLInput)
  return find(m, where = "$(string(column_name)) = $(escape_type(value))")
end

function find_one_by(m, column_name::Symbol, value::SQLInput)
  Nullable{JinnieModel}(find_by(m, symbol(column_name), value) |> first)
end

function rand(m; limit = 1)
  return Nullable{JinnieModel}( find(m, limit = SQLLimit(limit), order = [SQLOrder("random()")] ) |> first )
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
        value
      end

      push!(params, "$(string(field)) = $(escape_type(value))")
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
      value
    end

    push!(params, "$(string(field)) = $(escape_type(value))")
  end
  
  return eval(parse("""$m(; $(join(params, ",")) )"""))
end

function escape_type(value)
  return if isa(value, AbstractString)
    value = replace(value, "\$", "\\\$")
    "\"$value\""
  elseif isa(value, Char)
    "'$value'"
  else 
    value
  end
end

function all(m)
  find(m)
end

function save{T<:JinnieModel}(m::T; upsert_strategy = :none)
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

  return run_query_df(sql, supress_output = true)
end

@memoize function updatable_fields(m::JinnieModel)
  object_fields = map(x -> string(x), fieldnames(m))
  db_columns = columns(typeof(m))[:column_name]
  return intersect(object_fields, db_columns)
end

function build_save_sql(m::JinnieModel; upsert_strategy = :none) # upsert strateygy = :none | :error | :ignore | :update
  uf = updatable_fields(m)
  id_is_null = isa(getfield(m, symbol(m._id)), Nullable) && isnull( getfield(m, symbol(m._id)) )

  sql = if id_is_null || upsert_strategy != :none 
    pos = findfirst(uf, m._id)
    splice!(uf, pos)

    fields = join(uf, ", ")
    values = join( map(x -> prepare_for_db_save(m, symbol(x), getfield(m, symbol(x))), uf), ", " )

    "INSERT INTO $(m._table_name) ( $fields ) VALUES ( $values )" * if ( upsert_strategy == :error ) "" 
                                                                    elseif ( upsert_strategy == :ignore ) " ON CONFLICT DO NOTHING"
                                                                    elseif ( upsert_strategy == :update ) 
                                                                       " ON CONFLICT ($(m._id)) DO UPDATE SET $(update_query_part(m))"
                                                                    else ""
                                                                    end
  elseif !id_is_null && upsert_strategy == :none # id set and no upsert strategy, do a plain update
    "UPDATE $(m._table_name) SET $(update_query_part(m))"
  end 

  return sql * " RETURNING $(m._id)"
end

function update_query_part(m::JinnieModel)
  update_values = join( map(x -> "$x = $( prepare_for_db_save(m, symbol(x), getfield(m, symbol(x))) )", updatable_fields(m)), ", " )
  return " $update_values WHERE $(m._table_name).$(m._id) = '$(m.id)'"
end

function prepare_for_db_save(m::JinnieModel, field::Symbol, value)
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

function delete{T<:JinnieModel}(m::T)
  sql = "DELETE FROM $(m._table_name) WHERE $(m._id) = '$(m.id)'"
  run_query_df(sql)
  
  tmp = typeof(m)()
  m.id = tmp.id
  return m
end

function run_query_df(sql; supress_output = false) 
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

  if !supress_output Jinnie.log(df) end

  return df
end

end

M = Model