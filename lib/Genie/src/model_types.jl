import Base.string
import Base.print
import Base.show
import Base.convert
import Base.endof
import Base.length
import Base.next
import Base.==

export DbId, SQLType, AbstractModel
export SQLInput, SQLColumn, SQLColumns, SQLLogicOperator
export SQLWhere, SQLLimit, SQLOrder, SQLQuery, SQLRelation
export QI, QC, QLO, QW, QL, QO, QQ, QR

abstract SQLType <: Genie.GenieType
abstract AbstractModel <: Genie.GenieType

typealias DbId Int32
convert(::Type{Nullable{DbId}}, v::Number) = Nullable{DbId}(DbId(v))

#
# SQLInput
# 

type SQLInput <: AbstractString
  value::Union{AbstractString, Real}
  escaped::Bool
  raw::Bool
  SQLInput(v::Union{AbstractString, Real}; escaped = false, raw = false) = new(v, escaped, raw)
end
SQLInput(a::Array{Any}) = map(x -> SQLInput(x), a)
SQLInput(i::SQLInput) = i

==(a::SQLInput, b::SQLInput) = a.value == b.value

string(s::SQLInput) = safe(s).value
string(a::Array{SQLInput}) = join(map(x -> string(x), a), ",")
endof(s::SQLInput) = endof(s.value)
length(s::SQLInput) = length(s.value)
next(s::SQLInput, i::Int) = next(s.value, i)
safe(s::SQLInput) = escape_value(s)

print(io::IO, s::SQLInput) = print(io, string(s))
show(io::IO, s::SQLInput) = print(io, string(s))

convert(::Type{SQLInput}, r::Real) = SQLInput(parse(r))
convert(::Type{SQLInput}, s::Symbol) = SQLInput(string(s))
convert(::Type{SQLInput}, i::Nullable{Int32}) = (! isnull(i) ? Base.get(i) : -1) |> SQLInput
convert(::Type{SQLInput}, d::DateTime) = SQLInput(string(d))

QI = SQLInput

#
# SQLColumn
# 

type SQLColumn <: SQLType
  value::AbstractString
  escaped::Bool
  raw::Bool
  table_name::Union{AbstractString, Symbol}
  function SQLColumn(v::AbstractString; escaped = false, raw = false, table_name = "") 
    if v == "*" 
      raw = true 
    end
    new(v, escaped, raw, string(table_name))
  end
end
SQLColumn(v::Any; escaped = false, raw = false, table_name = "") = SQLColumn(string(v), escaped, raw, table_name)
SQLColumn(a::Array) = map(x -> SQLColumn(string(x)), a)
SQLColumn(c::SQLColumn) = c

==(a::SQLColumn, b::SQLColumn) = a.value == b.value 

string(a::Array{SQLColumn}) = join(map(x -> string(x), a), ", ")
string(s::SQLColumn) = safe(s).value
safe(s::SQLColumn) = escape_column_name(s)

convert(::Type{SQLColumn}, s::Symbol) = SQLColumn(string(s))
convert(::Type{SQLColumn}, s::ASCIIString) = SQLColumn(s)
convert(::Type{SQLColumn}, v::ASCIIString, e::Bool, r::Bool) = SQLColumn(v, escaped = e, raw = r)
convert(::Type{SQLColumn}, v::ASCIIString, e::Bool, r::Bool, t::Any) = SQLColumn(v, escaped = e, raw = r, table_name = string(t))

print(io::IO, a::Array{SQLColumn}) = print(io, string(a))
show(io::IO, a::Array{SQLColumn}) = print(io, string(a))
print(io::IO, s::SQLColumn) = print(io, string(s))
show(io::IO, s::SQLColumn) = print(io, string(s))

SQLColumns = SQLColumn # so we can use both
QC = SQLColumn

#
# SQLLogicOperator
# 

type SQLLogicOperator <: SQLType
  value::AbstractString
  SQLLogicOperator(v::AbstractString) = new( v == "OR" ? "OR" : "AND" )
end
SQLLogicOperator(v::Any) = SQLLogicOperator(string(v))
SQLLogicOperator() = SQLLogicOperator("AND")

string(s::SQLLogicOperator) = s.value

QLO = SQLLogicOperator

#
# SQLWhere
# 

type SQLWhere <: SQLType
  column::SQLColumn
  value::SQLInput
  condition::SQLLogicOperator
  operator::AbstractString

  SQLWhere(column::SQLColumn, value::SQLInput, condition::SQLLogicOperator, operator::AbstractString) = 
    new(column, value, condition, operator)
end
SQLWhere(column::Any, value::Any, condition::Any, operator::AbstractString) = SQLWhere(SQLColumn(column), SQLInput(value), SQLLogicOperator(condition), operator)
SQLWhere(column::SQLColumn, value::SQLInput, operator::AbstractString) = SQLWhere(column, value, SQLLogicOperator("AND"), operator)
SQLWhere(column::SQLColumn, value::SQLInput, condition::SQLLogicOperator) = SQLWhere(column, value, condition, "=")
SQLWhere(column::Any, value::Any, operator::Any) = SQLWhere(SQLColumn(column), SQLInput(value), SQLLogicOperator("AND"), operator)
SQLWhere(column::SQLColumn, value::SQLInput) = SQLWhere(column, value, SQLLogicOperator("AND"))
SQLWhere(column::Any, value::Any) = SQLWhere(SQLColumn(column), SQLInput(value))

string(w::SQLWhere) = "$(w.condition.value) ( $(w.column) $(w.operator) ( $(w.value) ) )"
function string{T <: AbstractModel}(w::SQLWhere, m::T) 
  w.column = SQLColumn(w.column.value, escaped = w.column.escaped, raw = w.column.raw, table_name = m._table_name)
  "$(w.condition.value) ( $(w.column) $(w.operator) ( $(w.value) ) )"
end
print{T<:SQLWhere}(io::IO, w::T) = print(io, Genie.genietype_to_print(w))
show{T<:SQLWhere}(io::IO, w::T) = print(io, Genie.genietype_to_print(w))

convert(::Type{Array{SQLWhere,1}}, w::SQLWhere) = [w]

SQLHaving = SQLWhere
QW = SQLWhere

#
# SQLLimit
# 

type SQLLimit <: SQLType
  value::Union{Int, AbstractString}
  SQLLimit(v::Int) = new(v)
  SQLLimit(v::AbstractString) = new("ALL")
end
SQLLimit() = SQLLimit("ALL")

string(l::SQLLimit) = string(l.value)
convert(::Type{Model.SQLLimit}, v::Int) = SQLLimit(v)

QL = SQLLimit

#
# SQLOrder
# 

type SQLOrder <: SQLType
  column::SQLColumn
  direction::AbstractString
  SQLOrder(column::SQLColumn, direction::AbstractString) = 
    new(column, uppercase(string(direction)) == "DESC" ? "DESC" : "ASC")
end
SQLOrder(column::Any, direction::Any; raw::Bool = false) = SQLOrder(SQLColumn(column, raw = raw), string(direction))
SQLOrder(column::Any; raw::Bool = false) = SQLOrder(SQLColumn(column, raw = raw), "ASC")
string(o::SQLOrder) = "($(o.column) $(o.direction))"

convert(::Type{Array{SQLOrder, 1}}, o::SQLOrder) = [o]

QO = SQLOrder

#
# SQLQuery
# 

type SQLQuery <: SQLType
  columns::Array{SQLColumn, 1} 
  where::Array{SQLWhere, 1} 
  limit::SQLLimit  
  offset::Int 
  order::Array{SQLOrder, 1} 
  group::Array{SQLColumn, 1} 
  having::Array{SQLWhere, 1}

  SQLQuery(;  columns = SQLColumn[], where = SQLWhere[], limit = SQLLimit("ALL"), offset = 0, 
              order = SQLOrder[], group = SQLColumn[], having = SQLWhere[]) = 
    new(columns, where, limit, offset, order, group, having)
end
string{T<:AbstractModel}(q::SQLQuery, m::Type{T}) = to_fetch_sql(m, q)
function string(_::SQLQuery)
  Genie.log("Can't generate the SQL Query string without an instance of a model. Please use string(q::SQLQuery, m::Type{AbstractModel}) instead.", :debug) 
  error("Incorrect string call")
end

QQ = SQLQuery

#
# SQLRelation
# 

type SQLRelation <: SQLType
  model_name::Symbol
  condition::Nullable{Array{SQLWhere, 1}}
  required::Bool
  eagerness::Symbol
  data::Nullable{AbstractModel}

  SQLRelation(model_name; condition = Nullable{Array{SQLWhere, 1}}(), required = true, eagerness = :auto, data = Nullable{AbstractModel}()) = 
    new(model_name, condition, required, eagerness, data)
end
function lazy(r::SQLRelation) 
  r.eagerness == MODEL_RELATIONSHIPS_EAGERNESS_LAZY || 
  r.eagerness == MODEL_RELATIONSHIPS_EAGERNESS_AUTO && Genie.config.model_relationships_eagerness == MODEL_RELATIONSHIPS_EAGERNESS_LAZY
end

QR = SQLRelation