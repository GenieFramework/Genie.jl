module Database

using YAML
using Genie
using Memoize

eval(:(using $(Genie.config.db_adapter)))
eval(:(const DatabaseAdapter = $(Genie.config.db_adapter)))
eval(:(export DatabaseAdapter))

@memoize function parse_connection_data()
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
      Nullable()
    end
  else
    error("DB configuration for $(Genie.config.app_env) not found")
  end

  Nullable()
end

@memoize function conn_data()
  Base.get(env_connection_data())
end

@memoize function db_connect(skip_db::Bool = false)
  env_db_conn_data = env_connection_data()
  if isnull(env_db_conn_data)
    error("Database connection failed")
  end

  env_db_conn_data = Base.get(env_db_conn_data)
  require(Symbol(conn_data()["adapter"] * "DatabaseAdapter"))
  DatabaseAdapter.adapter_connect(env_db_conn_data, skip_db)
end

@memoize function query_tools(skip_db::Bool = false)
  db_connect(skip_db), DatabaseAdapter.db_adapter()
end

function create_database()
  Logger.log("Not implemented - please manually create the database first, if it does not already exist", :debug)
end

function create_migrations_table()
  query(DatabaseAdapter.adapter_create_migrations_table_sql())
  Logger.log("Created table $(Genie.config.db_migrations_table_name) or table already exists")
end

function query(sql::AbstractString; skip_db::Bool = false, system_query::Bool = false)
  suppress_output = system_query || Genie.config.suppress_output
  conn, adapter = query_tools(skip_db)
  DatabaseAdapter.adapter_query(sql, suppress_output, conn, adapter, skip_db)
end

@memoize function escape_column_name(c::AbstractString)
  conn, adapter = query_tools()
  DatabaseAdapter.adapter_escape_column_name(c, conn, adapter)
end

@memoize function escape_value(v::Union{AbstractString, Real})
  conn, adapter = query_tools()
  adapter.escapeliteral(conn, v)
end

@memoize function table_columns(table_name::AbstractString)
  conn, adapter = query_tools()
  query_df(DatabaseAdapter.adapter_table_columns_sql(table_name), suppress_output = true)
end

function query_df(sql::AbstractString; suppress_output::Bool = false)
  conn, adapter = query_tools()
  DatabaseAdapter.adapter_query_df(sql, (suppress_output || Genie.config.suppress_output), conn, adapter)
end

Genie.config.db_auto_connect && db_connect()

end