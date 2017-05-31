module Toolbox

import Base.string

using Genie, Util, Millboard, FileTemplates, Configuration, Logger, Inflector

export TaskResult, VoidTaskResult

type TaskInfo
  file_name::String
  module_name::Symbol
  description::String
end

type TaskResult{T}
  code::Int
  message::String
  result::T
end


"""
    run_task(task_name::String, params...)

Runs the Genie task named `task_name`.
"""
function run_task(task_name::String, params...) :: TaskResult
  @time import_task(task_name).run_task!(params...)
end


"""
    import_task(task_name::String)

Brings the Genie task `task_name` into scope.
"""
function import_task(task_name::String) :: Module
  task_name = valid_task_name(task_name)
  tasks = all_tasks(filter_type_name = Symbol(task_name))

  if isempty(tasks)
    Logger.log("Task not found", :err)
    return
  end

  eval(tasks[1].module_name)
end


function VoidTaskResult()
  TaskResult(0, "", nothing)
end


"""
    valid_task_name(task_name::String) :: String

Attempts to convert a potentially invalid (partial) `task_name` into a valid one.
"""
function valid_task_name(task_name::String) :: String
  task_name = Inflector.from_underscores(task_name)
  endswith(task_name, "Task") || (task_name = task_name * "Task")

  task_name
end


"""
    print_tasks() :: Void

Prints a list of all the registered Genie tasks to the standard output.
"""
function print_tasks() :: Void
  output = ""
  arr_output = []
  for t in all_tasks()
    td = Genie.to_dict(t)
    push!(arr_output, [td["module_name"], td["file_name"], td["description"]])
  end

  Millboard.table(arr_output, :colnames => ["Task name \nFilename \nDescription "], :rownames => []) |> println
end


"""
    tasks(; filter_type_name = Symbol()) :: Vector{TaskInfo}
    all_tasks(; filter_type_name = Symbol()) :: Vector{TaskInfo}

Returns a vector of all registered Genie tasks.
"""
function tasks(; filter_type_name = Symbol()) :: Vector{TaskInfo}
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
const all_tasks = tasks


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
