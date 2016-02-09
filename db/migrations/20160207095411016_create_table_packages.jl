using Jinnie
using Database 

type CreateTablePackages
end 

function up(_::CreateTablePackages)
  conn, adapter = Database.query_tools()
  if ( adapter != Database.POSTGRESQL_ADAPTER ) error("Not implemented") end

  result = Database.query("""
    CREATE TABLE IF NOT EXISTS packages (
      name          varchar(100) CONSTRAINT idx_name PRIMARY KEY, 
      url           text,
      updated_at    timestamp DEFAULT current_timestamp
    )
  """)

  Jinnie.log("Executed migration CreateTablePackages::up")
end

function down(_::CreateTablePackages)
  conn, adapter = Database.query_tools()
  if ( adapter != Database.POSTGRESQL_ADAPTER ) error("Not implemented") end

  Database.query("DROP TABLE packages")

  Jinnie.log("Executed migration CreateTablePackages::down")
end