module Model

using Memoize
using Database
using DataFrames
using Genie
using Util

using Debug

include(abspath(joinpath("lib", "Genie", "src", "model_types.jl")))

# internals

const RELATIONSHIP_HAS_ONE = :has_one
const RELATIONSHIP_BELONGS_TO = :belongs_to
const RELATIONSHIP_HAS_MANY = :has_many
direct_relationships() = [RELATIONSHIP_HAS_ONE, RELATIONSHIP_BELONGS_TO, RELATIONSHIP_HAS_MANY]

#
# ORM methods
# 

function find_df{T<:AbstractModel}(m::Type{T}, q::SQLQuery)
  sql::UTF8String = to_fetch_sql(m, q)
  query(sql)::DataFrames.DataFrame
end

function find{T<:AbstractModel}(m::Type{T}, q::SQLQuery)
  result::DataFrames.DataFrame = find_df(m, q)
  to_models(m, result)
end
function find{T<:AbstractModel}(m::Type{T})
  find(m, SQLQuery())
end

function find_by{T<:AbstractModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput)
  find(m, SQLQuery(where = [SQLWhere(column_name, value)]))
end
function find_by{T<:AbstractModel}(m::Type{T}, column_name::Any, value::Any)
  find_by(m, SQLColumn(column_name), SQLInput(value))
end

function find_one_by{T<:AbstractModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput)
  find_by(m, column_name, value) |> to_nullable
end
function find_one_by{T<:AbstractModel}(m::Type{T}, column_name::Any, value::Any)
  find_one_by(m, SQLColumn(column_name), SQLInput(value))
end

function find_one{T<:AbstractModel}(m::Type{T}, value::Any)
  _m::T = disposable_instance(m)
  find_one_by(m, SQLColumn(_m._id), SQLInput(value))
end

function rand{T<:AbstractModel}(m::Type{T}; limit = 1)
  find(m, SQLQuery(limit = SQLLimit(limit), order = [SQLOrder("random()", raw = true)]))
end

function rand_one{T<:AbstractModel}(m::Type{T})
  result = rand(m, limit = 1)
  df ? result : to_nullable(result)
end

function all{T<:AbstractModel}(m::Type{T})
  find(m)
end

function save{T<:AbstractModel}(m::T; conflict_strategy = :error)
  try 
    save!(m, conflict_strategy = conflict_strategy, get_inserted = true)

    true
  catch ex
    Genie.log(ex)

    false
  end
end

function save!{T<:AbstractModel}(m::T; conflict_strategy = :error)
  sql::UTF8String = to_store_sql(m, conflict_strategy = conflict_strategy)
  query_result_df::DataFrames.DataFrame = query(sql)
  insert_id::Any = query_result_df[1, Symbol(m._id)]

  find_one_by(typeof(m), Symbol(m._id), insert_id)
end

function create_or_update_by!{T<:AbstractModel}(m::T, property::Symbol, value::Any)
  existing = find_one_by(typeof(m), property, value)
  if ! isnull(existing) 
    existing = Base.get(existing)
    
    for fieldname in fieldnames(typeof(m))
      ( startswith(string(fieldname), "_") || string(fieldname) == m._id ) && continue
      setfield!(existing, fieldname, getfield(m, fieldname))
    end
    
    return Model.save!(existing)
  else 
    return Model.save!(m)
  end
end
function create_or_update_by!{T<:AbstractModel}(m::T, property::Symbol)
  create_or_update_by!(m, property, getfield(m, property))
end

#
# Object generation 
# 

@debug function to_models{T<:AbstractModel}(m::Type{T}, df::DataFrames.DataFrame)
  models = Array{T, 1}()
  dfs = df_result_to_models_data(m, df)

  row_count::Int = 1
  for row in eachrow(df)
    main_model::T = to_model(m, dfs[disposable_instance(m)._table_name][row_count, :])

    for relationship in relationships(m)
      r::SQLRelation, r_type::Symbol = relationship

      lazy(r) && continue 

      related_model = constantize(r.model_name)
      related_model_df::DataFrames.DataFrame = dfs[disposable_instance(related_model)._table_name][row_count, :]
      r = set_relationship_data(r, related_model, related_model_df)

      if ! isdefined(:model_rels)
        model_rels::Dict{Symbol, SQLRelation} = getfield(main_model, r_type) |> Base.get
      end
      model_rels[Symbol(lowercase(string(r_type) * "_" * string(r.model_name)))] = r
    end

    push!(models, main_model)
    row_count += 1
  end

  return models
end

function set_relationship_data{T<:AbstractModel}(r::SQLRelation, related_model::Type{T}, related_model_df::DataFrames.DataFrame)
  r.data = Nullable( to_model(related_model, related_model_df) )

  r
end

function to_model{T<:AbstractModel}(m::Type{T}, row::DataFrames.DataFrameRow)
  _m::T = disposable_instance(m) 
  obj = m()
  sf = settable_fields(_m, row)

  for field in sf
    unq_field = from_fully_qualified(_m, field)

    isna(row[field]) && continue # if it's NA we just leave the default value of the empty obj

    value = if in(:on_hydration, fieldnames(_m))
              try 
                Base.get(_m.on_hydration)(_m, unq_field, row[field])
              catch ex
                Genie.log("Failed to hydrate field $field", :debug)
                Genie.log(ex)

                row[field]  
              end
            else 
              row[field]
            end

    setfield!(obj, unq_field, convert(typeof(getfield(_m, unq_field)), value))
  end

  obj
end

function to_model{T<:AbstractModel}(m::Type{T}, df::DataFrames.DataFrame)
  for row in eachrow(df)
    return to_model(m, row)
  end
end

# 
# Query generation
# 

function to_select_part{T<:AbstractModel}(m::Type{T}, cols::Array{SQLColumn, 1})
  _m = disposable_instance(m)

  function _to_select_part()
    joined_tables = [] 

    if has_relationship(_m, RELATIONSHIP_HAS_ONE)
      rels = Base.get(_m.has_one) |> values |> collect
      joined_tables = vcat(joined_tables, map(x -> lazy(x) ? nothing : disposable_instance(x.model_name), rels))
    end

    if has_relationship(_m, RELATIONSHIP_BELONGS_TO)
      rels = Base.get(_m.belongs_to) |> values |> collect
      joined_tables = vcat(joined_tables, map(x -> lazy(x) ? nothing : disposable_instance(x.model_name), rels))
    end

    filter!(x -> x != nothing, joined_tables)

    if ! isempty(cols)
      table_columns = []

      for column in cols 
        column_data = from_literal_column_name(column.value)
        if ! haskey(column_data, :table_name)
          column_data[:table_name] = _m._table_name
        end
        if ! haskey(column_data, :alias) 
          column_data[:alias] = ""
        end

        fccn = "$(to_fully_qualified(column_data[:column_name], column_data[:table_name])) AS $( isempty(column_data[:alias]) ? to_sql_column_name(column_data[:column_name], column_data[:table_name]) : column_data[:alias] )"
        push!(table_columns, fccn)
      end

      return join(table_columns, ", ")
    else 
      table_columns = join(to_fully_qualified_sql_column_names(_m, persistable_fields(_m), escape_columns = true), ", ")

      related_table_columns = []
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
function to_select_part{T<:AbstractModel}(m::Type{T}, c::SQLColumn)
  to_select_part(m, [c])
end
function to_select_part{T<:AbstractModel}(m::Type{T}, c::AbstractString)
  to_select_part(m, SQLColumn(c, raw = c == "*"))
end
function to_select_part{T<:AbstractModel}(m::Type{T})
  to_select_part(m, Array{SQLColumn, 1}())
end

function to_from_part{T<:AbstractModel}(m::Type{T})
  _m = disposable_instance(m)
  "FROM " * escape_column_name(_m._table_name)
end

function to_where_part{T<:AbstractModel}(m::Type{T}, w::Array{SQLWhere, 1})
  isempty(w) ? 
    "" :
    "WHERE " * (string(first(w).condition) == "AND" ? "TRUE " : "FALSE ") * join(map(wx -> string(wx, disposable_instance(m)), w), " ")
end

function to_order_part{T<:AbstractModel}(m::Type{T}, o::Array{SQLOrder, 1})
  isempty(o) ? 
    "" : 
    "ORDER BY " * join(map(x -> to_fully_qualified(m, x.column) * " " * x.direction, o), ", ")
end

function to_group_part(g::Array{SQLColumn, 1})
  isempty(g) ? 
    "" : 
    " GROUP BY " * join(map(x -> string(x), g), ", ")
end

function to_limit_part(l::SQLLimit)
  l.value != "ALL" ? "LIMIT " * (l |> string) : ""
end

function to_offset_part(o::Int)
  o != 0 ? "OFFSET " * (o |> string) : ""
end

function to_having_part(h::Array{SQLHaving, 1})
  isempty(h) ? 
    "" : 
    (string(first(h).condition) == "AND" ? "TRUE " : "FALSE ") * join(map(w -> string(w), h), " ")
end

function to_join_part{T<:AbstractModel}(m::Type{T})
  _m = disposable_instance(m)
  join_part = ""
   
  for rel in relationships(m)
    if ( first(rel) |> lazy ) continue end
    join_part *= (first(rel).required ? "INNER " : "LEFT ") * "JOIN " * relation_to_sql(_m, rel)
  end

  join_part
end

function relationships{T<:AbstractModel}(m::Type{T})
  _m = disposable_instance(m)
  # indirect_relationships = [:has_one_through, :has_many_through]

  rls = []

  for r in direct_relationships()
    if has_field(_m, r) && ! isnull(getfield(_m, r)) 
      relationship = Base.get(getfield(_m, r)) |> values |> collect
      if ! isempty(relationship) 
        for rel in relationship 
          push!(rls, (rel, r))
        end
      end
    end
  end

  rls
end

function relationship{T<:AbstractModel}(m::T, model_name::Symbol, relationship_type::Symbol)
  nullable_defined_rels::Nullable{Dict{Symbol, SQLRelation}} = getfield(m, relationship_type) 
  if ! isnull(nullable_defined_rels) 
    defined_rels::Array{SQLRelation, 1} = Base.get(nullable_defined_rels) |> values |> collect

    for rel::SQLRelation in defined_rels
      if rel.model_name == model_name
        return Nullable{SQLRelation}(rel)
      end
    end
  end

  Nullable{SQLRelation}()
end

function relationship_data!{T<:AbstractModel}(m::T, model_name::Symbol, relationship_type::Symbol)
  rel = relationship(m, model_name, relationship_type) |> Base.get
  if lazy(rel) && isnull(rel.data)
    return (get_relationship_data(m, rel, relationship_type) |> Base.get)::AbstractModel
  elseif ! isnull(rel.data)
    return Base.get(rel.data)::AbstractModel
  end
end

function get_relationship_data{T<:AbstractModel}(m::T, rel::SQLRelation, relationship_type::Symbol)
  conditions =  if ! isnull( rel.condition ) 
                  Base.get(rel.condition)
                else 
                  Array{SQLWhere, 1}()
                end
  limit = if relationship_type == RELATIONSHIP_HAS_ONE || relationship_type == RELATIONSHIP_BELONGS_TO
            1
          else 
            "ALL"
          end
  where = if relationship_type == RELATIONSHIP_HAS_ONE 
            SQLColumn( ( (lowercase(string(typeof(m))) |> strip_module_name) * "_" * m._id |> escape_column_name), raw = true ), m.id
          elseif relationship_type == RELATIONSHIP_BELONGS_TO
            _r = constantize(rel.model_name)()
            SQLColumn(to_fully_qualified(_r._id, _r._table_name), raw = true), getfield(m, Symbol((lowercase(string(typeof(_r))) |> strip_module_name) * "_" * _r._id)) |> Base.get
          end
  push!(conditions, SQLWhere(where...))
  data = Model.find( constantize(rel.model_name), SQLQuery( where = conditions, limit = limit ) )

  if isempty(data) return Nullable{AbstractModel}() end

  if relationship_type == RELATIONSHIP_HAS_ONE || relationship_type == RELATIONSHIP_BELONGS_TO
    return Nullable{AbstractModel}(first(data))
  else 
    return Nullable{AbstractModel}(data)
  end

  Nullable{AbstractModel}()
end

function df_result_to_models_data{T<:AbstractModel}(m::Type{T}, df::DataFrame)
  _m::T = disposable_instance(m)
  tables_names::Array{AbstractString, 1} = [_m._table_name]
  tables_columns = Dict()
  sub_dfs = Dict()
  
  function relationships_tables_names{T<:AbstractModel}(m::Type{T})
    for r in relationships(m)
      r, r_type = r
      rmdl = disposable_instance( constantize(r.model_name) )
      push!(tables_names, rmdl._table_name)
    end
  end

  function extract_columns_names()
    for t in tables_names
      tables_columns[t] = Array{Symbol, 1}()
    end

    for dfc in names(df)
      sdfc = string(dfc)
      ! contains(sdfc, "_") && continue 
      table_name = split(sdfc, "_")[1]
      ! in(table_name, tables_names) && continue
      push!(tables_columns[table_name], dfc)
    end
  end

  function split_dfs_by_table()
    for t in tables_names
      sub_dfs[t] = df[:, tables_columns[t]]
    end

    sub_dfs 
  end

  relationships_tables_names(m)
  extract_columns_names()
  split_dfs_by_table()
end

function relation_to_sql{T<:AbstractModel}(m::T, rel::Tuple{SQLRelation, Symbol})
  rel, rel_type = rel
  j = disposable_instance(rel.model_name)
  join_table_name = j._table_name

  if rel_type == RELATIONSHIP_BELONGS_TO 
    j, m = m, j
  end

  if isnull(rel.condition) 
    return    (join_table_name |> escape_column_name) * " ON " * 
              (j._table_name |> escape_column_name) * "." * 
                ( (lowercase(string(typeof(m))) |> strip_module_name) * "_" * m._id |> escape_column_name) * 
              " = " * 
              (m._table_name |> escape_column_name) * "." * 
                (m._id |> escape_column_name)
  else 
    conditions = Base.get(rel.condition)
    return to_where_part(m, conditions)
  end
end

function to_fetch_sql{T<:AbstractModel}(m::Type{T}, q::SQLQuery)
  sql::UTF8String = ( "$(to_select_part(m, q.columns)) $(to_from_part(m)) $(to_join_part(m)) $(to_where_part(m, q.where)) " * 
                      "$(to_group_part(q.group)) $(to_order_part(m, q.order)) " * 
                      "$(to_having_part(q.having)) $(to_limit_part(q.limit)) $(to_offset_part(q.offset))") |> strip
  replace(sql, r"\s+", " ")
end

function to_store_sql{T<:AbstractModel}(m::T; conflict_strategy = :error) # upsert strateygy = :none | :error | :ignore | :update
  uf = persistable_fields(m)

  sql = if ! persisted(m) || (persisted(m) && conflict_strategy == :update)
    pos = findfirst(uf, m._id) 
    pos > 0 && splice!(uf, pos)

    fields = SQLColumn(uf)
    vals = join( map(x -> string(prepare_for_db_save(m, Symbol(x), getfield(m, Symbol(x)))), uf), ", ")

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

function update_query_part{T<:AbstractModel}(m::T)
  update_values = join(map(x -> "$(string(SQLColumn(x))) = $( string(prepare_for_db_save(m, Symbol(x), getfield(m, Symbol(x)))) )", 
                            persistable_fields(m)), ", ")
  return " $update_values WHERE $(m._table_name).$(m._id) = '$(Base.get(m.id))'"
end

function prepare_for_db_save{T<:AbstractModel}(m::T, field::Symbol, value)
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

function delete_all{T<:AbstractModel}(m::Type{T}; truncate::Bool = true, reset_sequence::Bool = true, cascade::Bool = false)
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

function delete{T<:AbstractModel}(m::T)
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
  df::DataFrames.DataFrame = Database.query_df(sql)
  df
end

#
# sql utility queries
# 

function count{T<:AbstractModel}(m::Type{T})
  _m = disposable_instance(m)
  result::DataFrames.DataFrame = query("SELECT COUNT(*) AS $(_m._table_name)_count FROM $(_m._table_name)")

  result[1, Symbol("$(_m._table_name)_count")]
end

# 
# ORM utils
# 

function is_subtype{T<:AbstractModel}(m::Type{T}, parent_model = AbstractModel)
  return m <: parent_model
end

const model_prototypes = Dict{AbstractString, Any}()

function disposable_instance{T<:AbstractModel}(m::Type{T})
  type_name = string(m)
  haskey(model_prototypes, type_name) && return model_prototypes[type_name]

  if is_subtype(m)
    model_prototypes[type_name] = m()    
    return model_prototypes[type_name]
  else 
    error("$m is not a Model")
  end
end
function disposable_instance(model_name::Symbol)
  disposable_instance(eval(parse(string(model_name))))
end

@memoize function columns(m)
  _m = disposable_instance(m)
  Database.table_columns(_m._table_name)
end

function persisted{T<:AbstractModel}(m::T)
  ! ( isa(getfield(m, Symbol(m._id)), Nullable) && isnull( getfield(m, Symbol(m._id)) ) )
end

function persistable_fields{T<:AbstractModel}(m::T; fully_qualified::Bool = false)
  object_fields = map(x -> string(x), fieldnames(m))
  db_columns = columns(typeof(m))[:column_name]
  pst_fields = intersect(object_fields, db_columns)
  fully_qualified ? to_fully_qualified_sql_column_names(m, pst_fields) : pst_fields
end

function settable_fields{T<:AbstractModel}(m::T, row::DataFrames.DataFrameRow)
  df_cols::Array{Symbol, 1} = names(row)
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
    val = c.table_name != "" && ! startswith(c.value, (c.table_name * ".")) ? c.table_name * "." * c.value : c.value
    c.value = escape_column_name(val)
    c.escaped = true
  end

  c
end
@memoize function escape_column_name(s::AbstractString)
  join(map(x -> Database.escape_column_name(string(x)), split(s, ".")), ".")
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

function has_field{T<:AbstractModel}(m::T, f::Symbol)
  in(f, fieldnames(m))
end

function strip_table_name{T<:AbstractModel}(m::T, f::Symbol)
  replace(string(f), Regex("^$(m._table_name)_"), "", 1) |> Symbol
end

function is_fully_qualified{T<:AbstractModel}(m::T, f::Symbol)
  startswith(string(f), m._table_name) && has_field(m, strip_table_name(m, f))
end

function from_fully_qualified{T<:AbstractModel}(m::T, f::Symbol)
  is_fully_qualified(m, f) ? strip_table_name(m, f) : f
end

function strip_module_name(s::AbstractString)
  split(s, ".") |> last
end

function to_fully_qualified(v::AbstractString, t::AbstractString)
  t * "." * v
end
function to_fully_qualified{T<:AbstractModel}(m::T, v::AbstractString)
  to_fully_qualified(v, m._table_name)
end
function to_fully_qualified{T<:AbstractModel}(m::T, c::SQLColumn)
  c.raw && return c.value
  to_fully_qualified(c.value, m._table_name)
end
function to_fully_qualified{T<:AbstractModel}(m::Type{T}, c::SQLColumn)
  to_fully_qualified(disposable_instance(m), c)
end

function  to_sql_column_names{T<:AbstractModel}(m::T, fields::Array{Symbol, 1})
  map(x -> (to_sql_column_name(m, string(x))) |> Symbol, fields)
end

function to_sql_column_name(v::AbstractString, t::AbstractString)
  t * "_" * v
end
function to_sql_column_name{T<:AbstractModel}(m::T, v::AbstractString)
  to_sql_column_name(v, m._table_name)
end
function to_sql_column_name{T<:AbstractModel}(m::T, c::SQLColumn)
  to_sql_column_name(c.value, m._table_name)
end

function to_fully_qualified_sql_column_names{T<:AbstractModel, S<:AbstractString}(m::T, persistable_fields::Array{S, 1}; escape_columns::Bool = false)
  map(x -> to_fully_qualified_sql_column_name(m, x, escape_columns = escape_columns), persistable_fields)
end

function to_fully_qualified_sql_column_name{T<:AbstractModel}(m::T, f::AbstractString; escape_columns::Bool = false, alias::AbstractString = "")
  if escape_columns
    "$(to_fully_qualified(m, f) |> escape_column_name) AS $(isempty(alias) ? (to_sql_column_name(m, f) |> escape_column_name) : alias)"
  else 
    "$(to_fully_qualified(m, f)) AS $(isempty(alias) ? to_sql_column_name(m, f) : alias)"
  end
end

function from_literal_column_name(c::AbstractString)
  result = Dict{Symbol, AbstractString}()
  result[:original_string] = c

  # has alias? 
  if contains(c, " AS ") 
    parts = split(c, " AS ")
    result[:column_name] = parts[1]
    result[:alias] = parts[2]
  else 
    result[:column_name] = c
  end

  # is fully qualified? 
  if contains(result[:column_name], ".")
    parts = split(result[:column_name], ".")
    result[:table_name] = parts[1]
    result[:column_name] = parts[2]
  end

  result
end

function to_dict{T<:AbstractModel}(m::T; all_fields::Bool = false, expand_nullables::Bool = false)
  fields = all_fields ? fieldnames(m) : persistable_fields(m)
  [string(f) => Util.expand_nullable( getfield(m, Symbol(f)), expand_nullables ) for f in fields]
end
function to_dict{T<:GenieType}(m::T) 
  Genie.to_dict(m)
end

function to_string_dict{T<:AbstractModel}(m::T; all_fields::Bool = false, all_output::Bool = false) 
  fields = all_fields ? fieldnames(m) : persistable_fields(m)
  output_length = all_output ? 100_000_000 : Genie.config.output_length
  response = Dict{AbstractString, AbstractString}()
  for f in fields 
    key = string(f)
    value = string(getfield(m, Symbol(f)))
    if length(value) > output_length 
      value = value[1:output_length] * "..."
    end
    response[key] = value
  end
  
  response
end
function to_string_dict{T<:GenieType}(m::T) 
  Genie.to_string_dict(m)
end

function to_nullable(result)
  isempty(result) ? Nullable{AbstractModel}() : Nullable{AbstractModel}(result |> first)
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

function constantize(s::Symbol, m::Module = Genie)
  string(m) * "." * ucfirst(string(s)) |> parse |> eval
end

function has_relationship{T<:GenieType}(m::T, relationship_type::Symbol)
  has_field(m, relationship_type) && ! isnull(getfield(m, relationship_type))
end

function dataframe_to_dict(df::DataFrames.DataFrame)
  result = Array{Dict{Symbol, Any}, 1}()
  for r in eachrow(df)
    push!(result, Dict{Symbol, Any}( [k => r[k] for k in DataFrames.names(df)] ) )
  end

  result
end

end