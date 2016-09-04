using Genie
using Database

type CreateTableUserSessions
end

function up(::CreateTableUserSessions)
  Database.query("""
    CREATE TABLE IF NOT EXISTS user_sessions (
      user_id       integer,
      updated_at    timestamp DEFAULT current_timestamp,
      CONSTRAINT user_sessions__idx_id UNIQUE(user_id)
    )
  """)
end

function down(::CreateTableUserSessions)
  Database.query("DROP TABLE user_sessions")
end
