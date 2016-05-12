module Database

using YAML
using Genie
using Memoize

function parse_connection_data()
  YAML.load(open(abspath("config/database.yml")))
end

@memoize function env_connection_data()
  db_conn_data = parse_connection_data()

  if ( haskey(db_conn_data, Genie.config.app_env) ) 
    env_db_conn_data = db_conn_data[Genie.config.app_env]
    if ( haskey(env_db_conn_data, "adapter") )
      return Nullable(env_db_conn_data)
    else 
      error("Database config must define an adapter")
    end
  end
end

@memoize function db_connect(skip_db::Bool = false)
  env_db_conn_data = env_connection_data()
  if isnull(env_db_conn_data) 
    error("Database connection failed")
  end

  env_db_conn_data = Base.get(env_db_conn_data)
  joinpath("lib", "genie", "database_adapters", lowercase(conn_data()["adapter"]) * ".jl") |> abspath |> include
  current_module().adapter_connect(env_db_conn_data, skip_db)
end

@memoize function conn_data()
  Base.get(env_connection_data())
end

@memoize function query_tools(skip_db::Bool = false)
  conn = db_connect(skip_db)
  adapter = current_module().db_adapter()

  conn, adapter
end

function create_migrations_table()
  query(create_migrations_table_sql())
  Genie.log("Created table $(Genie.config.db_migrations_table_name) or table already exists")
end

function query(sql::AbstractString; skip_db::Bool = false, system_query::Bool = false)
  supress_output = system_query || config.supress_output
  conn, adapter = query_tools(skip_db)
  current_module().adapter_query(sql, supress_output, conn, adapter, skip_db)
end

@memoize function escape_column_name(c::AbstractString)
  conn, adapter = query_tools()
  current_module().adapter_escape_column_name(c, conn, adapter)
end

@memoize function escape_value(v::Union{AbstractString, Real})
  conn, adapter = query_tools()
  adapter.escapeliteral(conn, v)
end

@memoize function table_columns(table_name::AbstractString)
  conn, adapter = query_tools()
  query_df(current_module().adapter_table_columns_sql(table_name), supress_output = true)
end

function query_df(sql::AbstractString; supress_output::Bool = false) 
  supress_output = supress_output || config.supress_output
  conn, adapter = query_tools()
  current_module().adapter_query_df(sql, supress_output, conn, adapter)
end

end