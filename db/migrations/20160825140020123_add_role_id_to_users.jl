module AddRoleIdToUsers
using Database

function up()
  Database.query("""ALTER TABLE users ADD COLUMN role_id integer DEFAULT NULL""")
  Database.query("""CREATE INDEX users__idx_role_id ON users (role_id)""")
end

function down()
  Database.query("""DROP INDEX users__idx_role_id""")
  Database.query("""ALTER TABLE users DROP COLUMN role_id""")
end

end