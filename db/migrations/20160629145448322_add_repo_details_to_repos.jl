using Genie
using Database 

type AddRepoDetailsToRepos
end 

function up(_::AddRepoDetailsToRepos)
  Database.query("""ALTER TABLE repos ADD COLUMN name VARCHAR(50)""")
  Database.query("""ALTER TABLE repos ADD COLUMN description VARCHAR(1024)""")
  Database.query("""ALTER TABLE repos ADD COLUMN subscribers_count INTEGER""")
  Database.query("""ALTER TABLE repos ADD COLUMN forks_count INTEGER""")
  Database.query("""ALTER TABLE repos ADD COLUMN stargazers_count INTEGER""")
  Database.query("""ALTER TABLE repos ADD COLUMN watchers_count INTEGER""")
  Database.query("""ALTER TABLE repos ADD COLUMN open_issues_count INTEGER""")
end

function down(_::AddRepoDetailsToRepos)
  Database.query("""ALTER TABLE repos DROP name""")
  Database.query("""ALTER TABLE repos DROP description""")
  Database.query("""ALTER TABLE repos DROP subscribers_count""")
  Database.query("""ALTER TABLE repos DROP forks_count""")
  Database.query("""ALTER TABLE repos DROP stargazers_count""")
  Database.query("""ALTER TABLE repos DROP watchers_count""")
  Database.query("""ALTER TABLE repos DROP open_issues_count""")
end
