module AddPublishedStatusToArticles
using Database

function up()
  Database.query("""
    ALTER TABLE articles
      ADD COLUMN published_at timestamp DEFAULT NULL
  """)
  Database.query("""CREATE INDEX articles__idx_published_at ON articles (published_at)""")
end

function down()
  Database.query("""DROP INDEX articles__idx_published_at""")
  Database.query("""ALTER TABLE articles DROP COLUMN published_at""")
end

end