module Migration

using Genie
using Memoize
using Database
using FileTemplates
using Millboard
using Configuration

type DbMigration # todo: rename the "migration_" prefix for the fields
  migration_hash::AbstractString
  migration_file_name::AbstractString 
  migration_class_name::AbstractString
end

function new(cmd_args::Dict{AbstractString,Any}, config::Configuration.Config)
  mfn = migration_file_name(cmd_args, config)

  if ispath(mfn)
    error("Migration file already exists")
  end

  f = open(mfn, "w")
  write(f, FileTemplates.new_database_migration(migration_class_name(cmd_args["migration:new"])))
  close(f)

  Genie.log("New migration created at $mfn")
end

function migration_hash()
  m = match(r"(\d*)-(\d*)-(\d*)T(\d*):(\d*):(\d*)\.(\d*)", "$(Dates.unix2datetime(time()))")
  return join(m.captures)
end

function migration_file_name(cmd_args::Dict{AbstractString,Any}, config::Configuration.Config)
  return joinpath(config.db_migrations_folder, migration_hash() * "_" * cmd_args["migration:new"] * ".jl")
end

function migration_class_name(underscored_migration_name::AbstractString)
  mapreduce( x -> ucfirst(x), *, split(replace(underscored_migration_name, ".jl", ""), "_") )
end

function last_up()
  run_migration(last_migration(), :up)
end

function last_down()
  run_migration(last_migration(), :down)
end

function up_by_class_name(migration_class_name::AbstractString)
  migration = migration_by_class_name(migration_class_name)
  if migration != nothing 
    run_migration(migration, :up)
  else 
    error("Migration $migration_class_name not found")
  end
end

function down_by_class_name(migration_class_name::AbstractString)
  migration = migration_by_class_name(migration_class_name)
  if migration != nothing 
    run_migration(migration, :down)
  else 
    error("Migration $migration_class_name not found")
  end
end

function migration_by_class_name(migration_class_name::AbstractString)
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
  for (f in readdir(Genie.config.db_migrations_folder))
    if ( ismatch(r"\d{17}_.*\.jl", f) )
      parts = split(f, "_", limit = 2)
      push!(migrations, parts[1])
      migrations_files[parts[1]] = DbMigration(parts[1], f, migration_class_name(parts[2]))
    end
  end

  return sort!(migrations), migrations_files
end

@memoize function last_migration()
  migrations, migrations_files = all_migrations()
  return migrations_files[migrations[length(migrations)]]
end

function run_migration(migration::DbMigration, direction::Symbol)
  include(abspath(joinpath(Genie.config.db_migrations_folder, migration.migration_file_name)))
  eval(parse("$(current_module()).$(string(direction))($(current_module()).$(migration.migration_class_name)())")) 

  store_migration_status(migration, direction)

  ! Genie.config.supress_output && Genie.log("Executed migration $(migration.migration_class_name) $(direction)")
end

function store_migration_status(migration::DbMigration, direction::Symbol)
  if ( direction == :up )
    Database.query("INSERT INTO $(Genie.config.db_migrations_table_name) VALUES ('$(migration.migration_hash)')", system_query = true)
  else 
    Database.query("DELETE FROM $(Genie.config.db_migrations_table_name) WHERE version = ('$(migration.migration_hash)')", system_query = true)
  end
end

function upped_migrations()
  result = Database.query("SELECT * FROM $(Genie.config.db_migrations_table_name) ORDER BY version DESC", system_query = true)
  return map(x -> x[1], result)
end

function status()
  migrations, migrations_files = all_migrations()
  up_migrations = upped_migrations()
  arr_output = []
  
  for m in migrations
    sts = ( findfirst(up_migrations, m) > 0 ) ? :up : :down
    push!(arr_output, [migrations_files[m].migration_class_name * ": " * uppercase(string(sts)); migrations_files[m].migration_file_name])
  end

  Millboard.table(arr_output, :colnames => ["Class name & status \nFile name "], :rownames => []) |> println
end

function all_with_status()
  migrations, migrations_files = all_migrations()
  up_migrations = upped_migrations()
  indexes = []
  result = Dict()
  
  for m in migrations
    status = ( findfirst(up_migrations, m) > 0 ) ? :up : :down
    push!(indexes, migrations_files[m].migration_hash)
    result[migrations_files[m].migration_hash] = Dict(
      :migration => DbMigration(migrations_files[m].migration_hash, migrations_files[m].migration_file_name, migrations_files[m].migration_class_name), 
      :status => status
    )
  end

  indexes, result
end

function all_down()
  i, m = all_with_status()
  for v in values(m)
    if v[:status] == :up
      mm = v[:migration]
      down_by_class_name(mm.migration_class_name)
    end
  end
end

function all_up()
  i, m = all_with_status()
  for v in values(m)
    if v[:status] == :down
      mm = v[:migration]
      up_by_class_name(mm.migration_class_name)
    end
  end
end

end