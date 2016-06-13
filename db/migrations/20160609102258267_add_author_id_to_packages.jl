using Genie
using Database 

type AddAuthorIdToPackages
end 

function up(_::AddAuthorIdToPackages)
  Database.query("""ALTER TABLE packages ADD COLUMN author_id integer""")
  Database.query("""CREATE INDEX packages__idx_author_id ON packages (author_id)""")
end

function down(_::AddAuthorIdToPackages)
  Database.query("""DROP INDEX packages__idx_author_id""")
  Database.query("""ALTER TABLE packages DROP author_id""")
end
