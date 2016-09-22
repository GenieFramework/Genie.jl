import Base.string
import Base.print
import Base.show
import Base.convert
import Base.endof
import Base.length
import Base.next
import Base.==

export DbId, SQLType, AbstractModel, ModelValidator
export SQLInput, SQLColumn, SQLColumns, SQLLogicOperator
export SQLWhere, SQLLimit, SQLOrder, SQLQuery, SQLRelation
export SQLJoin, SQLOn, SQLJoinType
export QI, QC, QLO, QW, QL, QO, QQ, QR, QJ, QON, QJT

abstract SQLType <: Genie.GenieType
abstract AbstractModel <: Genie.GenieType

typealias DbId Int32
convert(::Type{Nullable{DbId}}, v::Number) = Nullable{DbId}(DbId(v))

typealias RelationshipData AbstractModel
typealias RelationshipDataArray Array{AbstractModel,1}

#
# Model validations
#

type ModelValidator
  rules::Vector{Tuple{Symbol,Function,Vararg{Any}}} # [(:title, :not_empty), (:title, :min_length, (20)), (:content, :not_empty_if_published), (:email, :matches, (r"(.*)@(.*)"))]
  errors::Vector{Tuple{Symbol,Symbol,String}} # [(:title, :not_empty, "title not empty"), (:title, :min_length, "min length 20"), (:content, :min_length, "min length 200")]

  ModelValidator(rules) = new(rules, Vector{Tuple{Symbol,Symbol,String}}())
end

#
# SQLInput
#

type SQLInput
  value::Union{String,Real}
  escaped::Bool
  raw::Bool
  SQLInput(v::Union{String, Real}; escaped = false, raw = false) = new(v, escaped, raw)
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
convert(::Type{SQLInput}, d::DateTime) = SQLInput(string(d))
function convert{T}(::Type{SQLInput}, n::Nullable{T})
  if isnull(n)
    SQLInput("NULL", escaped = true, raw = true)
  else
    Base.get(n) |> SQLInput
  end
end

const QI = SQLInput

#
# SQLColumn
#

type SQLColumn <: SQLType
  value::String
  escaped::Bool
  raw::Bool
  table_name::Union{String, Symbol}
  function SQLColumn(v::String; escaped = false, raw = false, table_name = "")
    if v == "*"
      raw = true
    end
    new(v, escaped, raw, string(table_name))
  end
end
function SQLColumn(v::Any; escaped = false, raw = false, table_name = "")
  if is_fully_qualified(string(v))
    table_name, v = from_fully_qualified(string(v))
  end
  SQLColumn(string(v), escaped = escaped, raw = raw, table_name = table_name)
end
SQLColumn(a::Array) = map(x -> SQLColumn(string(x)), a)
SQLColumn(c::SQLColumn) = c

==(a::SQLColumn, b::SQLColumn) = a.value == b.value

string(a::Array{SQLColumn}) = join(map(x -> string(x), a), ", ")
string(s::SQLColumn) = safe(s).value
safe(s::SQLColumn) = escape_column_name(s)

convert(::Type{SQLColumn}, s::Symbol) = SQLColumn(string(s))
convert(::Type{SQLColumn}, s::String) = SQLColumn(s)
convert(::Type{SQLColumn}, v::String, e::Bool, r::Bool) = SQLColumn(v, escaped = e, raw = r)
convert(::Type{SQLColumn}, v::String, e::Bool, r::Bool, t::Any) = SQLColumn(v, escaped = e, raw = r, table_name = string(t))

print(io::IO, a::Array{SQLColumn}) = print(io, string(a))
show(io::IO, a::Array{SQLColumn}) = print(io, string(a))
print(io::IO, s::SQLColumn) = print(io, string(s))
show(io::IO, s::SQLColumn) = print(io, string(s))

const SQLColumns = SQLColumn # so we can use both
const QC = SQLColumn

#
# SQLLogicOperator
#

type SQLLogicOperator <: SQLType
  value::String
  SQLLogicOperator(v::String) = new( v == "OR" ? "OR" : "AND" )
end
SQLLogicOperator(v::Any) = SQLLogicOperator(string(v))
SQLLogicOperator() = SQLLogicOperator("AND")

string(s::SQLLogicOperator) = s.value

const QLO = SQLLogicOperator

#
# SQLWhere
#

type SQLWhere <: SQLType
  column::SQLColumn
  value::SQLInput
  condition::SQLLogicOperator
  operator::String

  SQLWhere(column::SQLColumn, value::SQLInput, condition::SQLLogicOperator, operator::String) =
    new(column, value, condition, operator)
end
SQLWhere(column::Any, value::Any, condition::Any, operator::String) = SQLWhere(SQLColumn(column), SQLInput(value), SQLLogicOperator(condition), operator)
SQLWhere(column::SQLColumn, value::SQLInput, operator::String) = SQLWhere(column, value, SQLLogicOperator("AND"), operator)
SQLWhere(column::SQLColumn, value::SQLInput, condition::SQLLogicOperator) = SQLWhere(column, value, condition, "=")
SQLWhere(column::Any, value::Any, operator::Any) = SQLWhere(SQLColumn(column), SQLInput(value), SQLLogicOperator("AND"), operator)
SQLWhere(column::SQLColumn, value::SQLInput) = SQLWhere(column, value, SQLLogicOperator("AND"))
SQLWhere(column::Any, value::Any) = SQLWhere(SQLColumn(column), SQLInput(value))

string(w::SQLWhere) = "$(w.condition.value) ($(w.column) $(w.operator) $(enclosure(w.value, w.operator)))"
function string{T <: AbstractModel}(w::SQLWhere, m::T)
  w.column = SQLColumn(w.column.value, escaped = w.column.escaped, raw = w.column.raw, table_name = m._table_name)
  "$(w.condition.value) ($(w.column) $(w.operator) $(enclosure(w.value, w.operator)))"
end
print{T<:SQLWhere}(io::IO, w::T) = print(io, Genie.genietype_to_print(w))
show{T<:SQLWhere}(io::IO, w::T) = print(io, Genie.genietype_to_print(w))

convert(::Type{Array{SQLWhere,1}}, w::SQLWhere) = [w]

const SQLHaving = SQLWhere
const QW = SQLWhere

#
# SQLLimit
#

type SQLLimit <: SQLType
  value::Union{Int, String}
  SQLLimit(v::Int) = new(v)
  function SQLLimit(v::String)
    v = strip(uppercase(v))
    if v == "ALL"
      return new("ALL")
    else
      i = tryparse(Int, v)
      if isnull(i)
        error("Can't parse SQLLimit value")
      else
        return new(Base.get(i))
      end
    end
  end
end
SQLLimit() = SQLLimit("ALL")

string(l::SQLLimit) = string(l.value)

convert(::Type{Model.SQLLimit}, v::Int) = SQLLimit(v)

const QL = SQLLimit

#
# SQLOrder
#

type SQLOrder <: SQLType
  column::SQLColumn
  direction::String
  SQLOrder(column::SQLColumn, direction::String) =
    new(column, uppercase(string(direction)) == "DESC" ? "DESC" : "ASC")
end
SQLOrder(column::Any, direction::Any; raw::Bool = false) = SQLOrder(SQLColumn(column, raw = raw), string(direction))
SQLOrder(column::Any; raw::Bool = false) = SQLOrder(SQLColumn(column, raw = raw), "ASC")

string(o::SQLOrder) = "($(o.column) $(o.direction))"

convert(::Type{Array{SQLOrder,1}}, o::SQLOrder) = [o]
convert(::Type{Array{Model.SQLOrder,1}}, t::Tuple{Symbol,Symbol}) = SQLOrder(t[1], t[2])

const QO = SQLOrder

#
# SQLJoin
#

#
# SQLJoin - SQLOn
#

type SQLOn <: SQLType
  column_1::SQLColumn
  column_2::SQLColumn
  conditions::Array{SQLWhere,1}

  SQLOn(column_1, column_2; conditions = Array{SQLWhere,1}()) = new(column_1, column_2, conditions)
end
function string(o::SQLOn)
  on = " ON $(o.column_1) = $(o.column_2) "
  if ! isempty(o.conditions)
    on *= " AND " * join( map(x -> string(x), o.conditions), " AND " )
  end

  on
end

const QON = SQLOn

#
# SQLJoin - SQLJoinType
#

type SQLJoinType <: SQLType
  join_type::String
  function SQLJoinType(t::String)
    accepted_values = ["inner", "INNER", "left", "LEFT", "right", "RIGHT", "full", "FULL"]
    if in(t, accepted_values)
      new(uppercase(t))
    else
      error("""Invalid join type - accepted options are $(join(accepted_values, ", "))""")
      new("INNER")
    end
  end
end

convert(::Type{SQLJoinType}, s::String) = SQLJoinType(s)

string(jt::SQLJoinType) = jt.join_type

const QJT = SQLJoinType

#
# SQLJoin
#

type SQLJoin{T<:AbstractModel} <: SQLType
  model_name::Type{T}
  on::SQLOn
  join_type::SQLJoinType
  outer::Bool
  where::Array{SQLWhere,1}
  natural::Bool
  columns::Array{SQLColumns,1}
end
SQLJoin{T<:AbstractModel}(model_name::Type{T},
                          on::SQLOn;
                          join_type = SQLJoinType("INNER"),
                          outer = false,
                          where = Array{SQLWhere,1}(),
                          natural = false,
                          columns = Array{SQLColumns,1}()
                          ) = SQLJoin{T}(model_name, on, join_type, outer, where, natural, columns)
function string(j::SQLJoin)
  _m = disposable_instance(j.model_name)
  join = """ $(j.natural ? "NATURAL " : "") $(j.join_type) $(j.outer ? "OUTER " : "") JOIN $(Util.add_quotes(_m._table_name)) $(j.on) """
  join *= if ! isempty(j.where)
            where *= " WHERE " * join(map(x -> string(x), j.where), " AND ")
          else
            ""
          end

  join
end

convert(::Type{Array{SQLJoin,1}}, j::SQLJoin) = [j]

const QJ = SQLJoin

#
# SQLQuery
#

type SQLQuery <: SQLType
  columns::Array{SQLColumn,1}
  where::Array{SQLWhere,1}
  limit::SQLLimit
  offset::Int
  order::Array{SQLOrder,1}
  group::Array{SQLColumn,1}
  having::Array{SQLWhere,1}

  SQLQuery(;  columns = SQLColumn[], where = SQLWhere[], limit = SQLLimit("ALL"), offset = 0,
              order = SQLOrder[], group = SQLColumn[], having = SQLWhere[]) =
    new(columns, where, limit, offset, order, group, having)
end

string{T<:AbstractModel}(q::SQLQuery, m::Type{T}) = to_fetch_sql(m, q)

const QQ = SQLQuery

#
# SQLRelation
#

type SQLRelation{T<:AbstractModel} <: SQLType
  model_name::Type{T}
  required::Bool
  eagerness::Symbol
  data::Nullable{Union{RelationshipData, RelationshipDataArray}}
  join::Nullable{SQLJoin}

  SQLRelation(model_name, required, eagerness, data, join) = new(model_name, required, eagerness, data, join)
end
SQLRelation{T<:AbstractModel}(model_name::Type{T};
                              required = false,
                              eagerness = MODEL_RELATIONSHIPS_EAGERNESS_AUTO,
                              data = Nullable{Union{RelationshipData, RelationshipDataArray}}(),
                              join = Nullable{SQLJoin}()) = SQLRelation{T}(model_name, required, eagerness, data, join)
function lazy(r::SQLRelation)
  r.eagerness == MODEL_RELATIONSHIPS_EAGERNESS_LAZY ||
  r.eagerness == MODEL_RELATIONSHIPS_EAGERNESS_AUTO && Genie.config.model_relationships_eagerness == MODEL_RELATIONSHIPS_EAGERNESS_LAZY
end

const QR = SQLRelation