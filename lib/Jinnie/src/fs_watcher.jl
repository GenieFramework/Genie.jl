file_changes_check_frequency = 1
refreshed_at = time()
monitored_extensions = ["jl"]

function monitor_changes()
  sleep(file_changes_check_frequency)

  if fs_changes("./") 
    println("Reloading...")
    refreshed_at = time()

    load_dependencies()
    include_libs()
    include_resources()
    
    reload("Jinnie")
    reload("Mux")
    
    start_server(reload = true)
  end

  monitor_changes()
end

function walk_dir(dir)
  f = readdir(abspath(dir))
  for i in f
    full_path = joinpath(dir, i)
    # spaces = length(matchall(r"/", full_path))
    # println(" "^ (spaces * 3),  full_path)
    if isdir(full_path)
      walk_dir(full_path)
    else 
      if ( last( split(i, ['.']) ) in monitored_extensions ) 
        # println(" "^ (spaces * 3),  full_path)
        produce( full_path )
      end
    end
  end
end

function fs_changes(dir)
  for file_name in Task(() -> walk_dir(dir))
    # println(file_name)
    if ( stat(file_name).mtime > refreshed_at )
      return true
    end
  end

  false
end