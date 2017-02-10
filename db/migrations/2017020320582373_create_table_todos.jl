module CreateTableTodos

using Genie, Database

function up()
  Database.query("""CREATE SEQUENCE todos__seq_id""")
  Database.query("""
    CREATE TABLE IF NOT EXISTS todos (
      id            integer CONSTRAINT todos__idx_id PRIMARY KEY DEFAULT NEXTVAL('todos__seq_id'),
      title         varchar(500) NOT NULL,
      description   text NOT NULL,
      created_at    timestamp, 
      updated_at    timestamp DEFAULT current_timestamp
    )
  """)
  Database.query("""ALTER SEQUENCE todos__seq_id OWNED BY todos.id""")
end

function down()
  Database.query("DROP TABLE todos")
end

end
