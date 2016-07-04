using Genie
using Database 

type AddMoreInfoToRepos
end 

function up(_::AddMoreInfoToRepos)
  Database.query("""ALTER TABLE repos ADD COLUMN html_url VARCHAR(1024)""")
  Database.query("""ALTER TABLE repos ADD COLUMN github_pushed_at TIMESTAMP""")
  Database.query("""ALTER TABLE repos ADD COLUMN github_created_at TIMESTAMP""")
  Database.query("""ALTER TABLE repos ADD COLUMN github_updated_at TIMESTAMP""")
end

function down(_::AddMoreInfoToRepos)
  Database.query("""ALTER TABLE repos DROP html_url""")
  Database.query("""ALTER TABLE repos DROP github_pushed_at""")
  Database.query("""ALTER TABLE repos DROP github_created_at""")
  Database.query("""ALTER TABLE repos DROP github_updated_at""")
end
