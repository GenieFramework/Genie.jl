using Jinnie
using Util

type Task_Info
  file_name::AbstractString
  type_name::AbstractString
  instance
  description::AbstractString
end

function run_task(task_type_name)
  task = all_tasks(filter_type_name = task_type_name)
  current_module().run_task!(task.instance)
end

function list_tasks()
  println()
  for t in all_tasks()
    println( """$(t.file_name) \t|\t $(t.type_name) \t|\t $(t.description)""" )
  end
  println()
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
      ti = Task_Info(i, type_name, task_instance, current_module().description(task_instance))
      
      if ( filter_type_name == nothing ) push!(tasks, ti)
      elseif ( filter_type_name == type_name ) return ti
      end
    end
  end

  return tasks
end