using Genie
using Database 

type AddDetailsToAuthors
end 

function up(_::AddDetailsToAuthors)
  Database.query("""ALTER TABLE authors ADD COLUMN fullname VARCHAR(100)""")
  Database.query("""ALTER TABLE authors ADD COLUMN company VARCHAR(100)""")
  Database.query("""ALTER TABLE authors ADD COLUMN location VARCHAR(255)""")
  Database.query("""ALTER TABLE authors ADD COLUMN html_url VARCHAR(1024)""")
  Database.query("""ALTER TABLE authors ADD COLUMN blog_url VARCHAR(1024)""")
  Database.query("""ALTER TABLE authors ADD COLUMN followers_count INTEGER""")
end

function down(_::AddDetailsToAuthors)
  Database.query("""ALTER TABLE authors DROP fullname""")
  Database.query("""ALTER TABLE authors DROP company""")
  Database.query("""ALTER TABLE authors DROP location""")
  Database.query("""ALTER TABLE authors DROP html_url""")
  Database.query("""ALTER TABLE authors DROP blog_url""")
  Database.query("""ALTER TABLE authors DROP followers_count""")
end
