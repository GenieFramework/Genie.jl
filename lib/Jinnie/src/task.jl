type Task_Info
  file_name::AbstractString
  type_name::AbstractString
  instance
  description::AbstractString
end

module Task

using Jinnie
using Util
using Millboard
using FileTemplates
using Debug

function run_task(task_type_name)
  task = all_tasks(filter_type_name = task_type_name)
  if isa(task, Array) error("Task not found") end
  current_module().run_task!(task.instance)
end

function print_all_tasks()
  output = ""
  arr_output = []
  for t in all_tasks()
    td = Jinnie.to_dict(t)
    push!(arr_output, [td["type_name"], td["file_name"], td["description"]])
  end

  Millboard.table(arr_output, :colnames => ["Task name \nFilename \nDescription "], :rownames => []) |> println
end

function all_tasks(; filter_type_name = nothing)
  tasks = []

  tasks_folder = abspath(Jinnie.config.tasks_folder)
  f = readdir(tasks_folder)
  for i in f
    if ( endswith(i, "_task.jl") ) 
      include_path = joinpath(tasks_folder, i)
      include(include_path)
      
      type_name = Util.file_name_to_type_name(i)
      task_instance = eval(parse(string(current_module()) * "." * type_name * "()"))
      ti = Jinnie.Task_Info(i, type_name, task_instance, current_module().description(task_instance))
      
      if ( filter_type_name == nothing ) push!(tasks, ti)
      elseif ( filter_type_name == type_name ) return ti
      end
    end
  end

  return tasks
end

function new(cmd_args, config)
  tfn = task_file_name(cmd_args, config)
  
  if ispath(tfn)
    error("Task file already exists")
  end

  f = open(tfn, "w")
  write(f, FileTemplates.new_task(task_class_name(cmd_args["task:new"])))
  close(f)

  Jinnie.log("New task created at $tfn")
end

function task_file_name(cmd_args, config)
  return joinpath(config.tasks_folder, cmd_args["task:new"] * ".jl")
end

function task_class_name(underscored_task_name)
  mapreduce( x -> ucfirst(x), *, split(replace(underscored_task_name, ".jl", ""), "_") )
end

end