module AddSlugToArticles

using Database

function up()
  Database.query("""ALTER TABLE articles ADD COLUMN slug varchar(150) NOT NULL""")
  Database.query("""CREATE UNIQUE INDEX articles__idx_slug ON articles (slug)""")
end

function down()
  Database.query("DROP INDEX articles__idx_slug")
  Database.query("""ALTER TABLE users DROP COLUMN slug""")
end

end
