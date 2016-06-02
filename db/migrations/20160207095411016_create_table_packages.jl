using Genie
using Database 

type CreateTablePackages
end 

function up(_::CreateTablePackages)
  Database.query("""CREATE SEQUENCE packages__seq_id""")
  Database.query("""
    CREATE TABLE IF NOT EXISTS packages (
      id            integer CONSTRAINT packages__idx_id PRIMARY KEY DEFAULT NEXTVAL('packages__seq_id'), 
      name          varchar(100) NOT NULL, 
      url           text NOT NULL,
      updated_at    timestamp DEFAULT current_timestamp, 
      CONSTRAINT packages__idx_name UNIQUE(name)
      -- CONSTRAINT packages__idx_url UNIQUE(url)
    )
  """)
  Database.query("""ALTER SEQUENCE packages__seq_id OWNED BY packages.id;""")
end

function down(_::CreateTablePackages)
  Database.query("DROP TABLE packages")
end