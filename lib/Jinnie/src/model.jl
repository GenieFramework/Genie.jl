module Model

using Database
using DataFrames
using Jinnie

include(abspath(joinpath("lib", "Jinnie", "src", "model_types.jl")))

# internals

const RELATIONSHIP_HAS_ONE = :has_one
const RELATIONSHIP_BELONGS_TO = :belongs_to
const RELATIONSHIP_HAS_MANY = :has_many
direct_relationships() = [RELATIONSHIP_HAS_ONE, RELATIONSHIP_BELONGS_TO, RELATIONSHIP_HAS_MANY]

#
# ORM methods
# 

function find_df{T<:JinnieModel}(m::Type{T}, q::SQLQuery)
  query(to_fetch_sql(m, q))
end

function find{T<:JinnieModel}(m::Type{T}, q::SQLQuery; df::Bool = false)
  result = find_df(m, q)
  df ? result : to_models(m, result)
end
function find{T<:JinnieModel}(m::Type{T}; df::Bool = false)
  find(m, SQLQuery(), df = df)
end

function find_by{T<:JinnieModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput; df::Bool = false)
  find(m, SQLQuery(where = [SQLWhere(column_name, value)]), df = df)
end
function find_by{T<:JinnieModel}(m::Type{T}, column_name::Any, value::Any; df::Bool = false)
  find_by(m, SQLColumn(column_name), SQLInput(value), df = df)
end

function find_one_by{T<:JinnieModel}(m::Type{T}, column_name::SQLColumn, value::SQLInput; df::Bool = false)
  result = find_by(m, column_name, value, df = df)
  df ? result : to_nullable(result)
end
function find_one_by{T<:JinnieModel}(m::Type{T}, column_name::Any, value::Any; df::Bool = false)
  find_one_by(m, SQLColumn(column_name), SQLInput(value), df = df)
end

function find_one{T<:JinnieModel}(m::Type{T}, value::Any; df::Bool = false)
  _m = disposable_instance(m)
  find_one_by(m, SQLColumn(_m._id), SQLInput(value), df = df)
end

function rand{T<:JinnieModel}(m::Type{T}; limit = 1, df::Bool = false)
  find(m, SQLQuery(limit = SQLLimit(limit), order = [SQLOrder("random()", raw = true)]), df = df)
end

function rand_one{T<:JinnieModel}(m::Type{T}; df::Bool = false)
  result = rand(m, limit = 1, df = df)
  df ? result : to_nullable(result)
end

function all{T<:JinnieModel}(m::Type{T}; df::Bool = false)
  find(m, df = df)
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

@debug function to_models{T<:JinnieModel}(m::Type{T}, df::DataFrames.DataFrame)
  models = []

  for row in eachrow(df)
    dfs = df_result_to_models_data(m, df)
    main_model = to_model(m, dfs[disposable_instance(m)._table_name])

    # @bp
    index = 1
    for relationship in relationships(m)
      r, r_type = relationship
      related_model = constantize(r.model_name)
      related_model_df = dfs[disposable_instance(related_model)._table_name]

      # @bp
      r.data = Nullable( to_model(related_model, related_model_df) )
      r.raw_data = Nullable(related_model_df)

      model_rels = getfield(main_model, r_type) |> Base.get # []
      model_rels[index] = r

      index += 1
    end

    push!(models, main_model)
  end

  #+TODO: delete me
  #+TODO: you're here
  # Jinnie.log("Good job! You now have the models for each relationship - and you need to implement the accessor methods.", :debug) <-- 
  # Jinnie.log("Also, look into lazy and eager relationships - so you skip joining with the resources if not necessary", :debug)
  # Jinnie.log("Now, check out 'models', it's where you're at", :debug)

  # @bp
  return models
end

@debug function to_model{T<:JinnieModel}(m::Type{T}, row::DataFrames.DataFrameRow)
  _m = disposable_instance(m) 
  obj = m()
  sf = settable_fields(_m, row)
  # @bp

  for field in sf
    unq_field = from_fully_qualified(_m, field)
    value = if in(:on_hydration, fieldnames(_m))
              try 
                Base.get(_m.on_hydration)(_m, unq_field, row[field])
              catch ex
                Jinnie.log("Failed to hydrate field $field", :debug)
                Jinnie.log(ex)

                row[field]  
              end
            else 
              row[field]
            end

    # @bp
    setfield!(obj, unq_field, convert(typeof(getfield(_m, unq_field)), value))
  end

  obj
end

@debug function to_model{T<:JinnieModel}(m::Type{T}, df::DataFrames.DataFrame)
  for row in eachrow(df)
    return to_model(m, row)
  end
end

# 
# Query generation
# 

@debug function to_select_part{T<:JinnieModel}(m::Type{T}, c::Array{SQLColumn, 1})
  _m = disposable_instance(m)
  "SELECT " * if ( length(c) > 0 ) string(c)
              else 
                joined_tables = [] 

                # @bp
                if has_relationship(_m, RELATIONSHIP_HAS_ONE)
                  rels = Base.get(_m.has_one)
                  joined_tables = vcat(joined_tables, map(x -> disposable_instance(x.model_name), rels))
                end

                if has_relationship(_m, RELATIONSHIP_BELONGS_TO)
                  rels = Base.get(_m.belongs_to)
                  joined_tables = vcat(joined_tables, map(x -> disposable_instance(x.model_name), rels))
                end

                # @bp
                table_columns = join(to_fully_qualified_sql_column_names(_m, persistable_fields(_m), escape_columns = true), ", ")
                related_table_columns = []
                for rels in map(x -> to_fully_qualified_sql_column_names(x, persistable_fields(x), escape_columns = true), joined_tables)
                  for col in rels
                    push!(related_table_columns, col)
                  end
                end
                join([table_columns ; related_table_columns], ", ")
              end
end
function to_select_part{T<:JinnieModel}(m::Type{T}, c::SQLColumn)
  to_select_part(m, [c])
end
function to_select_part{T<:JinnieModel}(m::Type{T}, c::AbstractString)
  to_select_part(m, SQLColumn(c, raw = c == "*"))
end
function to_select_part{T<:JinnieModel}(m::Type{T})
  to_select_part(m, Array{SQLColumn, 1}())
end

function to_from_part{T<:JinnieModel}(m::Type{T})
  _m = disposable_instance(m)
  "FROM " * escape_column_name(_m._table_name)
end

function to_where_part{T<:JinnieModel}(m::Type{T}, w::Array{SQLWhere, 1})
  isempty(w) ? 
    "" :
    "WHERE " * (string(first(w).condition) == "AND" ? "TRUE " : "FALSE ") * join(map(wx -> string(wx, disposable_instance(m)), w), " ")
end

function to_order_part{T<:JinnieModel}(m::Type{T}, o::Array{SQLOrder, 1})
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

function to_join_part{T<:JinnieModel}(m::Type{T})
  _m = disposable_instance(m)
  join_part = ""
   
  for rel in relationships(m)
    join_part *= (first(rel).required ? "INNER " : "LEFT ") * "JOIN " * relation_to_sql(_m, rel)
  end

  join_part
end

function relationships{T<:JinnieModel}(m::Type{T})
  _m = disposable_instance(m)
  # indirect_relationships = [:has_one_through, :has_many_through]

  relationships = []

  for r in direct_relationships()
    if has_field(_m, r) && ! isnull(getfield(_m, r)) 
      relationship = Base.get(getfield(_m, r)) 
      if ! isempty(relationship) 
        for rel in relationship 
          push!(relationships, (rel, r))
        end
      end
    end
  end

  relationships
end

@debug function df_result_to_models_data{T<:JinnieModel}(m::Type{T}, df::DataFrame)
  _m = disposable_instance(m)
  tables_names = [_m._table_name]
  tables_columns = Dict()
  sub_dfs = Dict()
  
  function relationships_tables_names{T<:JinnieModel}(m::Type{T})
    for r in relationships(m)
      # @bp
      r, r_type = r
      rm = disposable_instance( constantize(r.model_name) )
      push!(tables_names, rm._table_name)
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
      # @bp
      push!(tables_columns[table_name], dfc)
    end
  end

  function split_dfs_by_table()
    # @bp
    for t in tables_names
      sub_dfs[t] = df[:, tables_columns[t]]
    end

    sub_dfs 
  end

  relationships_tables_names(m)
  extract_columns_names()
  split_dfs_by_table()
end

function relation_to_sql{T<:JinnieModel}(m::T, rel::Tuple{SQLRelation, Symbol})
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

function to_fetch_sql{T<:JinnieModel}(m::Type{T}, q::SQLQuery)
  sql = ("$(to_select_part(m, q.columns)) $(to_from_part(m)) $(to_join_part(m)) $(to_where_part(m, q.where)) " * 
          "$(to_group_part(q.group)) $(to_order_part(m, q.order)) " * 
          "$(to_having_part(q.having)) $(to_limit_part(q.limit)) $(to_offset_part(q.offset))") |> strip
  replace(sql, r"\s+", " ")
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
  Database.query_df(sql)
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
function disposable_instance(m::Symbol)
  "Jinnie." * ucfirst(string(m)) |> parse |> eval |> disposable_instance
end

@memoize function columns(m)
  _m = disposable_instance(m)
  Database.table_columns(_m._table_name)
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

function strip_module_name(s::AbstractString)
  split(s, ".") |> last
end

function to_fully_qualified(v::AbstractString, t::AbstractString)
  t * "." * v
end
function to_fully_qualified{T<:JinnieModel}(m::T, v::AbstractString)
  to_fully_qualified(v, m._table_name)
end
function to_fully_qualified{T<:JinnieModel}(m::T, c::SQLColumn)
  c.raw && return c.value
  to_fully_qualified(c.value, m._table_name)
end
function to_fully_qualified{T<:JinnieModel}(m::Type{T}, c::SQLColumn)
  to_fully_qualified(disposable_instance(m), c)
end

function  to_sql_column_names{T<:JinnieModel}(m::T, fields::Array{Symbol, 1})
  map(x -> (to_sql_column_name(m, string(x))) |> Symbol, fields)
end

function to_sql_column_name(v::AbstractString, t::AbstractString)
  t * "_" * v
end
function to_sql_column_name{T<:JinnieModel}(m::T, v::AbstractString)
  to_sql_column_name(v, m._table_name)
end
function to_sql_column_name{T<:JinnieModel}(m::T, c::SQLColumn)
  to_sql_column_name(c.value, m._table_name)
end

function to_fully_qualified_sql_column_names{T<:JinnieModel, S<:AbstractString}(m::T, persistable_fields::Array{S, 1}; escape_columns::Bool = false)
  map(x -> to_fully_qualified_sql_column_name(m, x, escape_columns = escape_columns), persistable_fields)
end

function to_fully_qualified_sql_column_name{T<:JinnieModel}(m::T, f::AbstractString; escape_columns::Bool = false)
  if escape_columns
    "$(to_fully_qualified(m, f) |> escape_column_name) AS $(to_sql_column_name(m, f) |> escape_column_name)"
  else 
    "$(to_fully_qualified(m, f)) AS $(to_sql_column_name(m, f))"
  end
end

function to_dict{T<:JinnieModel}(m::T; all_fields::Bool = false) 
  fields = all_fields ? fieldnames(m) : persistable_fields(m)
  [string(f) => getfield(m, Symbol(f)) for f in fields]
end
function to_dict{T<:JinnieType}(m::T) 
  Jinnie.to_dict(m)
end

@debug function to_string_dict{T<:JinnieModel}(m::T; all_fields::Bool = false, all_output::Bool = false) 
  fields = all_fields ? fieldnames(m) : persistable_fields(m)
  output_length = all_output ? 100_000_000 : Jinnie.config.output_length
  # @bp
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

function constantize(s::Symbol, m::Module = Jinnie)
  string(m) * "." * ucfirst(string(s)) |> parse |> eval
end

function has_relationship{T<:JinnieType}(m::T, relationship_type::Symbol)
  has_field(m, relationship_type) && ! isnull(getfield(m, relationship_type))
end

end

M = Model