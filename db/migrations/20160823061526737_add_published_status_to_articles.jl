using Genie, Database

type AddPublishedStatusToArticles
end

function up(_::AddPublishedStatusToArticles)
  Database.query("""
    ALTER TABLE articles
      ADD COLUMN published_at timestamp DEFAULT NULL,
      ADD COLUMN removed_at timestamp DEFAULT NULL;
  """)
  Database.query("""CREATE INDEX articles__idx_published_at ON articles (published_at)""")
  Database.query("""CREATE INDEX articles__idx_removed_at ON articles (removed_at)""")
end

function down(_::AddPublishedStatusToArticles)
  Database.query("""DROP INDEX articles__idx_removed_at""")
  Database.query("""DROP INDEX articles__idx_published_at""")
  Database.query("""ALTER TABLE articles DROP COLUMN removed_at""")
  Database.query("""ALTER TABLE articles DROP COLUMN published_at""")
end
