using Genie
using Database 

type CreateTableAuthors
end 

function up(_::CreateTableAuthors)
  Database.query("""CREATE SEQUENCE authors__seq_id""")
  Database.query("""
    CREATE TABLE IF NOT EXISTS authors (
      id            integer CONSTRAINT authors__idx_id PRIMARY KEY DEFAULT NEXTVAL('authors__seq_id'), 
      name          varchar(100) NOT NULL, 
      CONSTRAINT authors__idx_name UNIQUE(name)
    )
  """)
  Database.query("""ALTER SEQUENCE authors__seq_id OWNED BY authors.id;""")
end

function down(_::CreateTableAuthors)
  Database.query("DROP TABLE authors")
end
