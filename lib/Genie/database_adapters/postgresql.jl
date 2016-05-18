using PostgreSQL
using DataFrames
using Genie
using Database

export adapter_connect, db_adapter, adapter_table_columns_sql, create_migrations_table_sql, adapter_escape_column_name
export adapter_query_df, adapter_query

const DEFAULT_PORT = 5432

function adapter_connect(conn_data::Dict, skip_db::Bool = false)
  connect(Postgres, 
          conn_data["host"] == nothing ? "localhost" : conn_data["host"], 
          conn_data["username"], 
          conn_data["password"] == nothing ? "" : conn_data["password"], 
          conn_data["database"] == nothing || skip_db ? "" : conn_data["database"], 
          conn_data["port"] == nothing ? DEFAULT_PORT : conn_data["port"])
end

function adapter_table_columns_sql(table_name::AbstractString)
  "SELECT 
    column_name, ordinal_position, column_default, is_nullable, data_type, character_maximum_length, 
    udt_name, is_identity, is_updatable
  FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = '$table_name'"
end

function create_migrations_table_sql()
  "CREATE TABLE $(config.db_migrations_table_name) (version varchar(30) CONSTRAINT firstkey PRIMARY KEY)"
end

function adapter_escape_column_name(c::AbstractString, conn, adapter)
  strptr = adapter.PQescapeIdentifier(conn.ptr, c, sizeof(c))
  str = bytestring(strptr)
  adapter.PQfreemem(strptr)

  str
end

function adapter_query_df(sql::AbstractString, supress_output::Bool, conn, adapter)
  df::DataFrames.DataFrame = adapter.fetchdf(adapter_query(sql, supress_output, conn, adapter, false))
  Genie.@unless(supress_output || ! Genie.config.debug_db, Genie.log(df))

  df
end

function adapter_query(sql::AbstractString, supress_output::Bool, conn, adapter, skip_db::Bool)
  stmt = adapter.prepare(conn, sql)

  result = if supress_output || ! Genie.config.debug_db
    adapter.execute(stmt)
  else 
    Genie.log("SQL QUERY: $(escape_string(sql))")
    Genie.@run_with_time adapter.execute(stmt)
  end
  adapter.finish(stmt)

  if ( adapter.errstring(result) != "" )
    error("$(string(adapter)) error: $(adapter.errstring(result)) [$(adapter.errcode(result))]")
  end

  result
end

function db_adapter()
  PostgreSQL
end