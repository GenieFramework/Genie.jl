using Genie, Database

type AddSlugToArticles
end

function up(::AddSlugToArticles)
  Database.query("""ALTER TABLE articles ADD COLUMN slug varchar(150) NOT NULL""")
  Database.query("""CREATE UNIQUE INDEX articles__idx_slug ON articles (slug)""")
end

function down(::AddSlugToArticles)
  Database.query("DROP INDEX articles__idx_slug")
  Database.query("""ALTER TABLE users DROP COLUMN slug""")
end
