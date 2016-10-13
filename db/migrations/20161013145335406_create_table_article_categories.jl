module CreateTableArticleCategories
using Genie, Database

function up()
  Database.query("CREATE SEQUENCE IF NOT EXISTS article_categories__seq_id")
  Database.query("
    CREATE TABLE IF NOT EXISTS article_categories (
      id            integer CONSTRAINT article_categories__idx_id PRIMARY KEY DEFAULT NEXTVAL('article_categories__seq_id'),
      article_id    integer NOT NULL,
      category_id   integer NOT NULL
    )
  ")
  Database.query("ALTER SEQUENCE article_categories__seq_id OWNED BY article_categories.id")
end

function down()
  Database.query("DROP TABLE IF EXISTS article_categories")
  Database.query("DROP SEQUENCE IF EXISTS article_categories__seq_id")
end

end
