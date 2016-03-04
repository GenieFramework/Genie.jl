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

export DbId

abstract SQLType <: JinnieType

type SQLString <: AbstractString
  value::AbstractString
  SQLString(v::AbstractString) = new(v)
end
SQLString(a::Array) = map(x -> SQLString(x), a)
string(a::Array{SQLString}) = join(map(x -> string(SQLString(x)), a), ",")
string(s::SQLString) = safe(s.value)
print(io::IO, s::SQLString) = print(io, string(s))
show(io::IO, s::SQLString) = print(io, string(s))
convert(::Type{SQLString}, r::Real) = SQLString(string(r))
endof(s::SQLString) = endof(s.value)
length(s::SQLString) = length(s.value)
next(s::SQLString, i::Int) = next(s.value, i)
safe(s::SQLString) = safe(s.value)

safe(s::AbstractString) = Jinnie.Database.escape_value(s)
safe(n::Real) = n

type SQLReal <: Real
  value::Real
  SQLReal(v::Real) = new(v)
end
SQLReal(a::Array) = map(x -> SQLReal(x), a)
string(a::Array{SQLReal}) = join(map(x -> string(SQLReal(x)), a), ",")
string(s::SQLReal) = safe(s.value)
print(io::IO, s::SQLReal) = print(io, string(s))
show(io::IO, s::SQLReal) = print(io, string(s))
safe(s::SQLReal) = s.value
convert(::Type{SQLReal}, r::Nullable{Int32}) = SQLReal(Base.get(r))

SQLInput = Union{SQLString, SQLReal}
convert(::Type{SQLInput}, s::AbstractString) = SQLString(s)
convert(::Type{SQLInput}, s::Real) = SQLReal(s)

type SQLColumn <: SQLType
  value::AbstractString
  SQLColumn(v::Symbol) = new(string(v))
end
function SQLColumn(v::AbstractString) 
  if contains(v, ",") && !( startswith(v, "(") && endswith(v, ")") )
    return map(x -> SQLColumn(symbol(strip(x))), split(v, ","))
  else 
    return SQLColumn(symbol(strip(v)))
  end
end
SQLColumn(a::Array) = map(x -> SQLColumn(string(x)), a)
string(a::Array{SQLColumn}) = join(map(x -> string(x), a), ", ")
print(io::IO, a::Array{SQLColumn}) = print(io, string(a))
show(io::IO, a::Array{SQLColumn}) = print(io, string(a))
string(s::SQLColumn) = safe(s)
print(io::IO, s::SQLColumn) = print(io, string(s))
show(io::IO, s::SQLColumn) = print(io, string(s))
safe(s::SQLColumn) = Jinnie.Database.escape_column_name(s.value)

SQLColumns = SQLColumn # so we can use both

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
string(w::SQLWhere) = "$(w.condition.value) ( $(string(w.column)) $(w.operator) ( $(string(w.value)) ) )"
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

typealias DbId Int32
convert(::Type{Nullable{DbId}}, v::Number) = Nullable{DbId}(DbId(v))

type SQLOrder <: SQLType
  column::SQLIdentifier
  direction::AbstractString
  SQLOrder(column::Any, direction::Any) = new(  endswith(string(column), "()") ? SQLFunction(string(column)) : SQLColumn(string(column)), 
                                                uppercase(string(direction)) == "DESC" ? "DESC" : "ASC" )
end
SQLOrder(column::Any) = SQLOrder(column, "ASC")

type SQLQuery <: SQLType
  columns::Array{SQLColumn} 
  where::Array{SQLWhere} 
  limit::SQLLimit  
  offset::Int 
  order::Array{SQLOrder} 
  group::Array{SQLColumn} 
  having::Array{SQLWhere}

  SQLQuery(; columns = SQLColumn[], where = SQLWhere[], limit = SQLLimit("ALL"), offset = 0, order = SQLOrder[], group = SQLColumn[], having = SQLWhere[]) = 
    new(columns, where, limit, offset, order, group, having)
end

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

function prepare(m, q::SQLQuery)
  _m = disposable_instance(m)

  columns_part =  if ( length(q.columns) > 0 ) string(q.columns)
                  else join(updatable_fields(_m), ", ")
                  end

  where_part =    if ( length(q.where) == 0 ) "TRUE"
                  else (q.where[1].condition.value == "AND" ? "TRUE " : "FALSE ") * join(map(w -> string(w), q.where), " ")
                  end

  order_part =    if ( length(q.order) == 0 ) _m._id
                  else join(map(x -> "$(x.column.value) $(x.direction)", q.order), ", ")
                  end

  group_part =    if ( length(q.group) > 0 ) " GROUP BY " * join(map(x -> safe(x.value), q.group), ", ")
                  else ""
                  end

  having_part =   if ( length(q.having) == 0 ) "TRUE"
                  else (q.having[1].condition.value == "AND" ? "TRUE " : "FALSE ") * join(map(w -> string(w), q.having), " ")
                  end

  Dict(:columns_part => columns_part, :where_part => where_part, :order_part => order_part, :group_part => group_part, :limit => q.limit, :offset => q.offset, :having_part => having_part)
end

function to_sql(m, parts::Dict)
  _m = disposable_instance(m)
  """SELECT $(parts[:columns_part]) FROM $(_m._table_name) WHERE $(parts[:where_part]) $(parts[:group_part]) ORDER BY $(parts[:order_part]) LIMIT $(parts[:limit].value) OFFSET $(parts[:offset])"""
end

function find_df(m, q::SQLQuery)
  query(to_sql(m, prepare(m, q)))
end

function find(m, q::SQLQuery)
  to_models(m, find_df(m, q))
end
function find(m)
  find(m, SQLQuery())
end

function find_by(m, column_name::SQLColumn, value::SQLInput)
  find(m, SQLQuery(where = [SQLWhere(column_name, value)]))
end
function find_by(m, column_name::Any, value::Any)
  find_by(m, SQLColumn(column_name), SQLInput(value))
end

function find_one_by(m, column_name::SQLColumn, value::SQLInput)
  to_nullable(find_by(m, column_name, value))
end
function find_one_by(m, column_name::Any, value::Any)
  find_one_by(m, SQLColumn(column_name), SQLInput(value))
end

function rand(m; limit = 1)
  find(m, SQLQuery(limit = SQLLimit(limit), order = [SQLOrder("random()")]) )
end

function rand_one(m)
  to_nullable(rand(m, limit = 1))
end

function to_nullable(result)
  isempty(result) ? Nullable{JinnieModel}() : Nullable{JinnieModel}(result |> first)
end

function query(sql::AbstractString)
  run_query_df(sql)
end

function to_models(m, df::DataFrames.DataFrame)
  models = []
  for row in eachrow(df)
    push!(models, to_model(m, row))
  end

  return models
end

function to_model(m, row::DataFrames.DataFrameRow)
   _m = disposable_instance(m) 
  fields = fieldnames(_m)
  df_cols = names(row)
  settable_fields = intersect(fields, df_cols)

  obj = m()

  for field in settable_fields
    value = try 
      Base.get(_m.on_hydration)(_m, field, row[field])
    catch 
      row[field]
    end
    setfield!(obj, symbol(field), convert(typeof(getfield(_m, symbol(field))), value))
  end

  obj    
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

function all(m)
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
  sql = save_sql(m, conflict_strategy = conflict_strategy)
  to_models(typeof(m), query(sql)) |> first
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

function save_sql(m::JinnieModel; conflict_strategy = :error) # upsert strateygy = :none | :error | :ignore | :update
  uf = updatable_fields(m)

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

function persisted(m::JinnieModel)
  ! ( isa(getfield(m, symbol(m._id)), Nullable) && isnull( getfield(m, symbol(m._id)) ) )
end

function update_query_part(m::JinnieModel)
  update_values = join(map(x -> "$(string(SQLColumn(x))) = $( string(prepare_for_db_save(m, symbol(x), getfield(m, symbol(x)))) )", updatable_fields(m)), ", ")
  return " $update_values WHERE $(m._table_name).$(m._id) = '$(get(m.id))'"
end

function prepare_for_db_save(m::JinnieModel, field::Symbol, value)
  value = try 
            Base.get(m.on_dehydration)(m, field, value)
          catch 
            value
          end
  return  if isa(value, AbstractString) || isa(value, Char)
            SQLString(value)
          else SQLReal(value)
          end
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

  query(sql)
end

function delete{T<:JinnieModel}(m::T)
  sql = "DELETE FROM $(m._table_name) WHERE $(m._id) = '$(m.id)'"
  query(sql)
  
  tmp = typeof(m)()
  m.id = tmp.id
  return m
end

function run_query_df(sql::AbstractString; supress_output = false) 
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