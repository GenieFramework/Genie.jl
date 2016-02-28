module Migrations

using Memoize
using Database
using Jinnie
using FileTemplates

type Migration # todo: rename the "migration_" prefix for the fields
  migration_hash::AbstractString
  migration_file_name::AbstractString 
  migration_class_name::AbstractString
end

function new(cmd_args, config)
  mfn = migration_file_name(cmd_args, config)
  f = open(mfn, "w")
  write(f, FileTemplates.new_database_migration(migration_class_name(cmd_args["db:migration:new"])))
  close(f)

  Jinnie.log("New migration created at $mfn")
end

function migration_hash()
  m = match(r"(\d*)-(\d*)-(\d*)T(\d*):(\d*):(\d*)\.(\d*)", "$(Dates.unix2datetime(time()))")
  return join(m.captures)
end

function migration_file_name(cmd_args, config)
  return config.db_migrations_folder * "/" * migration_hash() * "_" * cmd_args["db:migration:new"] * ".jl"
end

function migration_class_name(underscored_migration_name)
  mapreduce( x -> ucfirst(x), *, split(replace(underscored_migration_name, ".jl", ""), "_") )
end

function last_up()
  run_migration(last_migration(), :up)
end

function last_down()
  run_migration(last_migration(), :down)
end

function up_by_class_name(migration_class_name)
  migration = migration_by_class_name(migration_class_name)
  if migration != nothing 
    run_migration(migration, :up)
  else 
    error("Migration $migration_class_name not found")
  end
end

function down_by_class_name(migration_class_name)
  migration = migration_by_class_name(migration_class_name)
  if migration != nothing 
    run_migration(migration, :down)
  else 
    error("Migration $migration_class_name not found")
  end
end

function migration_by_class_name(migration_class_name)
  ids, migrations = all_migrations()
  for id in ids
    migration = migrations[id]
    if migration.migration_class_name == migration_class_name 
      return migration
    end
  end

  return nothing # TODO: use nullables
end

@memoize function all_migrations()
  migrations = []
  migrations_files = Dict()
  for (f in readdir(Jinnie.config.db_migrations_folder))
    if ( ismatch(r"\d{17}_.*\.jl", f) )
      parts = split(f, "_", limit = 2)
      push!(migrations, parts[1])
      migrations_files[parts[1]] = Migration(parts[1], f, migration_class_name(parts[2]))
    end
  end

  return sort!(migrations), migrations_files
end

@memoize function last_migration()
  migrations, migrations_files = all_migrations()
  return migrations_files[migrations[length(migrations)]]
end

function run_migration(migration, direction)
  include(abspath(joinpath(Jinnie.config.db_migrations_folder, migration.migration_file_name)))
  eval(parse("Jinnie.$(string(direction))(Jinnie.$(migration.migration_class_name)())")) 

  store_migration_status(migration, direction)
end

function store_migration_status(migration, direction)
  if ( direction == :up )
    Database.query("INSERT INTO $(Jinnie.config.db_migrations_table_name) VALUES ('$(migration.migration_hash)')")
  else 
    Database.query("""DELETE FROM $(Jinnie.config.db_migrations_table_name) WHERE version = ('$(migration.migration_hash)')""")
  end
end

function upped_migrations()
  result = Database.query("SELECT * FROM $(Jinnie.config.db_migrations_table_name) ORDER BY version DESC")
  return map(x -> x[1], result)
end

function status()
  migrations, migrations_files = all_migrations()
  up_migrations = upped_migrations()

  println("")
  
  for m in migrations
    status = ( findfirst(up_migrations, m) > 0 ) ? "up" : "down"
    println( "$m \t|\t $status \t|\t $(migrations_files[m].migration_class_name) \t|\t $(migrations_files[m].migration_file_name)" )
  end

  println("")
end

end