module CreateTableCategories
using Genie, Database

function up()
  Database.query("CREATE SEQUENCE categories__seq_id")
  Database.query("
    CREATE TABLE IF NOT EXISTS categories (
      id            integer CONSTRAINT categories__idx_id PRIMARY KEY DEFAULT NEXTVAL('categories__seq_id'),
      name          varchar(50) NOT NULL,
      updated_at    timestamp DEFAULT current_timestamp,
      CONSTRAINT categories__idx_name UNIQUE(name)
    )
  ")
  Database.query("ALTER SEQUENCE categories__seq_id OWNED BY categories.id")
end

function down()
  Database.query("DROP TABLE categories")
end

end
