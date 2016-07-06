using Genie
using Database 

type AddExtraIndexesToRepos
end 

function up(_::AddExtraIndexesToRepos)
  Database.query("""CREATE INDEX repos__idx_stargazers_count ON repos (stargazers_count)""")
  Database.query("""CREATE INDEX repos__idx_github_created_at ON repos (github_created_at)""")
  Database.query("""CREATE INDEX repos__idx_github_pushed_at ON repos (github_pushed_at)""")
end

function down(_::AddExtraIndexesToRepos)
  Database.query("""DROP INDEX repos__idx_github_pushed_at""")
  Database.query("""DROP INDEX repos__idx_github_created_at""")
  Database.query("""DROP INDEX repos__idx_stargazers_count""")
end
