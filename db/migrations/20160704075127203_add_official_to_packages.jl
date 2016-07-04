using Genie
using Database 

type AddOfficialToPackages
end 

function up(_::AddOfficialToPackages)
  Database.query("""ALTER TABLE packages ADD COLUMN official BOOLEAN DEFAULT FALSE""")
end

function down(_::AddOfficialToPackages)
  Database.query("""ALTER TABLE packages DROP official""")
end
