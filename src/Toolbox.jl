module Toolbox

using Genie, Util, Millboard, FileTemplates, Configuration, Logger

type TaskInfo
  file_name::String
  module_name::Symbol
  description::String
end


"""
    run_task(task_type_name)

Executes a Genie task.
"""
function run_task(task_type_name)
  tasks = all_tasks(filter_type_name = Symbol(task_type_name))

  isempty(tasks) && (Logger.log("Task not found", :err) & return)
  eval(tasks[1].module_name).run_task!()
end # todo -- type unstable -- make tasks return TaskResult(code: , message: , result: )


"""
    print_all_tasks() :: Void

Prints a list of all the registered Genie tasks to the standard output.
"""
function print_all_tasks() :: Void
  output = ""
  arr_output = []
  for t in all_tasks()
    td = Genie.to_dict(t)
    push!(arr_output, [td["module_name"], td["file_name"], td["description"]])
  end

  Millboard.table(arr_output, :colnames => ["Task name \nFilename \nDescription "], :rownames => []) |> println
end


"""
    all_tasks(; filter_type_name = Symbol()) :: Vector{TaskInfo}

Returns a vector of all registered Genie tasks.
"""
function all_tasks(; filter_type_name = Symbol()) :: Vector{TaskInfo}
  tasks = TaskInfo[]

  tasks_folder = abspath(Genie.config.tasks_folder)
  f = readdir(tasks_folder)
  for i in f
    if ( endswith(i, "Task.jl") )
      push!(LOAD_PATH, tasks_folder)

      module_name = Util.file_name_without_extension(i) |> Symbol
      eval(:(using $(module_name)))
      ti = TaskInfo(i, module_name, eval(module_name).description())

      if ( filter_type_name == Symbol() ) push!(tasks, ti)
      elseif ( filter_type_name == module_name ) return TaskInfo[ti]
      end
    end
  end

  tasks
end


"""
    new(cmd_args::Dict{String,Any}, config::Settings) :: Void

Generates a new Genie task file.
"""
function new(cmd_args::Dict{String,Any}, config::Settings) :: Void
  tfn = task_file_name(cmd_args, config)

  if ispath(tfn)
    error("Task file already exists")
  end

  f = open(tfn, "w")
  write(f, FileTemplates.new_task(task_module_name(cmd_args["task:new"])))
  close(f)

  Logger.log("New task created at $tfn")

  nothing
end


"""
    task_file_name(cmd_args::Dict{String,Any}, config::Settings) :: String

Computes the name of a Genie task based on the command line input.
"""
function task_file_name(cmd_args::Dict{String,Any}, config::Settings) :: String
  joinpath(config.tasks_folder, cmd_args["task:new"] * ".jl")
end


"""
    task_module_name(underscored_task_name::String) :: String

Computes the name of a Genie task based on the command line input.
"""
function task_module_name(underscored_task_name::String) :: String
  mapreduce( x -> ucfirst(x), *, split(replace(underscored_task_name, ".jl", ""), "_") )
end

end
