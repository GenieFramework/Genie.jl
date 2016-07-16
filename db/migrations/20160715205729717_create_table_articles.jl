using Genie
using Database

type CreateTableArticles
end

function up(_::CreateTableArticles)
  Database.query("""CREATE SEQUENCE articles__seq_id""")
  Database.query("""
    CREATE TABLE IF NOT EXISTS articles (
      id            integer CONSTRAINT articles__idx_id PRIMARY KEY DEFAULT NEXTVAL('articles__seq_id'),
      title         varchar(500) NOT NULL,
      summary       text NOT NULL,
      content       text NOT NULL,
      updated_at    timestamp DEFAULT current_timestamp,
      CONSTRAINT articles__idx_name UNIQUE(title)
    )
  """)
  Database.query("""ALTER SEQUENCE articles__seq_id OWNED BY articles.id;""")
end

function down(_::CreateTableArticles)
  Database.query("DROP TABLE articles")
end