using Genie
using Database

type CreateTableUsers
end

function up(::CreateTableUsers)
  Database.query("""CREATE SEQUENCE users__seq_id""")
  Database.query("""
    CREATE TABLE IF NOT EXISTS users (
      id            integer CONSTRAINT users__idx_id PRIMARY KEY DEFAULT NEXTVAL('users__seq_id'),
      name          varchar(100) NOT NULL,
      email         text NOT NULL,
      password      varchar(256) NOT NULL,
      updated_at    timestamp DEFAULT current_timestamp,
      CONSTRAINT users__idx_name UNIQUE(email)
    )
  """)
  Database.query("""ALTER SEQUENCE users__seq_id OWNED BY users.id""")
end

function down(::CreateTableUsers)
  Database.query("DROP TABLE users")
end