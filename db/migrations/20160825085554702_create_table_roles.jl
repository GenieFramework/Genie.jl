using Genie, Database

type CreateTableRoles
end

function up(_::CreateTableRoles)
  Database.query("""CREATE SEQUENCE roles__seq_id""")
  Database.query("""
    CREATE TABLE IF NOT EXISTS roles (
      id            integer CONSTRAINT roles__idx_id PRIMARY KEY DEFAULT NEXTVAL('roles__seq_id'),
      name          varchar(20) NOT NULL,
      CONSTRAINT    roles__idx_id UNIQUE(id),
      CONSTRAINT    roles__idx_name UNIQUE(name)
    )
  """)
  Database.query("""ALTER SEQUENCE roles__seq_id OWNED BY roles.id""")
end

function down(_::CreateTableRoles)
  Database.query("""
    DROP TABLE roles
  """)
end
