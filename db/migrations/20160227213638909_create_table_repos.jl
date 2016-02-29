using Jinnie
using Database 

type CreateTableRepos
end 

function up(_::CreateTableRepos)
  conn, adapter = Database.query_tools()
  if ( adapter != Database.POSTGRESQL_ADAPTER ) error("Not implemented") end

  Database.query("""CREATE SEQUENCE repos__seq_id""")
  Database.query("""
    CREATE TABLE IF NOT EXISTS repos (
      id              integer CONSTRAINT repo__idx_id PRIMARY KEY DEFAULT NEXTVAL('repos__seq_id'), 
      package_id      integer, 
      fullname        varchar(100) NOT NULL, 
      readme          text,
      participation   text,
      updated_at      timestamp DEFAULT current_timestamp, 
      CONSTRAINT repo__idx_fullname UNIQUE(fullname), 
      CONSTRAINT repo__idx_package_id UNIQUE(package_id)
    )
  """)
  Database.query("""ALTER SEQUENCE repos__seq_id OWNED BY repos.id;""")

  Jinnie.log("Executed migration CreateTableRepos::up")
end

function down(_::CreateTableRepos)
  conn, adapter = Database.query_tools()
  if ( adapter != Database.POSTGRESQL_ADAPTER ) error("Not implemented") end

  Database.query("DROP TABLE repos")

  Jinnie.log("Executed migration CreateTableRepos::down")
end