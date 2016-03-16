import Base.string
import Base.print
import Base.show
import Base.convert
import Base.endof
import Base.length
import Base.next
import Base.==

export DbId
export SQLInput, SQLColumn, SQLColumns, SQLLogicOperator
export SQLWhere, SQLLimit, SQLOrder, SQLQuery
export QI, QC, QLO, QW, QL, QO, QQ

abstract SQLType <: JinnieType

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

QI = SQLInput

#
# SQLColumn
# 

type SQLColumn <: SQLType
  value::AbstractString
  escaped::Bool
  raw::Bool
  SQLColumn(v::AbstractString; escaped = false, raw = false) = new(v, escaped, raw)
  SQLColumn(v::Symbol; escaped = false, raw = false) = new(string(v), escaped, raw)
end
SQLColumn(a::Array) = map(x -> SQLColumn(string(x)), a)
SQLColumn(c::SQLColumn) = c

==(a::SQLColumn, b::SQLColumn) = a.value == b.value 

string(a::Array{SQLColumn}) = join(map(x -> string(x), a), ", ")
string(s::SQLColumn) = safe(s).value
safe(s::SQLColumn) = escape_column_name(s)

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
  SQLLogicOperator(v::Any) = new(string(v))
  SQLLogicOperator() = new("AND")
end
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
SQLWhere(column::SQLColumn, value::SQLInput, condition::SQLLogicOperator) = SQLWhere(column, value, condition, "=")
SQLWhere(column::SQLColumn, value::SQLInput) = SQLWhere(column, value, SQLLogicOperator("AND"))
SQLWhere(column::Any, value::Any) = SQLWhere(SQLColumn(column), SQLInput(value))

string(w::SQLWhere) = "$(w.condition.value) ( $(w.column) $(w.operator) ( $(w.value) ) )"
print{T<:SQLWhere}(io::IO, w::T) = print(io, "$(Jinnie.jinnietype_to_print(w)) \n $(string(w))")
show{T<:SQLWhere}(io::IO, w::T) = print(io, "$(Jinnie.jinnietype_to_print(w)) \n $(string(w))")

QW = SQLWhere

#
# SQLLimit
# 

type SQLLimit <: SQLType
  value::Union{Int, AbstractString}
  SQLLimit(v::Int) = new(v)
  SQLLimit(v::AbstractString) = new("ALL")
  SQLLimit() = new("ALL")
end
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

QO = SQLOrder

#
# SQLQuery
# 

type SQLQuery <: SQLType
  columns::Array{SQLColumn} 
  where::Array{SQLWhere} 
  limit::SQLLimit  
  offset::Int 
  order::Array{SQLOrder} 
  group::Array{SQLColumn} 
  having::Array{SQLWhere}

  SQLQuery(;  columns = SQLColumn[], where = SQLWhere[], limit = SQLLimit("ALL"), offset = 0, 
              order = SQLOrder[], group = SQLColumn[], having = SQLWhere[]) = 
    new(columns, where, limit, offset, order, group, having)
end
string{T<:JinnieModel}(q::SQLQuery, m::Type{T}) = to_fetch_sql(m, prepare(m, q))

QQ = SQLQuery