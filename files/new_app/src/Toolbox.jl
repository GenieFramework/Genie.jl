module Toolbox

import Base.string

using Revise, Genie, Genie.Util, Millboard, Genie.FileTemplates, Genie.Configuration, Genie.Loggers, Genie.Inflector

export TaskResult, VoidTaskResult, check_valid_task

const TASK_SUFFIX = "Task"

mutable struct TaskInfo
  file_name::String
  module_name::Symbol
  description::String
end

mutable struct TaskResult{T}
  code::Int
  message::String
  result::T
end


"""
    run_task(task_name::String; params...)
    function run_task(task::Module; params)

Runs the Genie task named `task_name`.
"""
function run_task(task_name::Union{String,Symbol}; params...)
  @time Base.invokelatest(import_task(string(task_name)).run_task, params)
end
function run_task(task::Module; params...)
  @time task.run_task(params)
end


"""
    import_task(task_name::String)

Brings the Genie task `task_name` into scope.
"""
function import_task(task_name::String) :: Module
  task_name = valid_task_name(task_name)
  tasks = all_tasks(filter_type_name = Symbol(task_name))

  if isempty(tasks)
    log("Task not found", :err)
    return
  end

  Core.eval(@__MODULE__, tasks[1].module_name)
  is_dev() && Revise.track(joinpath(Genie.TASKS_PATH, tasks[1].file_name))
end


function VoidTaskResult()
  TaskResult(0, "", nothing)
end


"""
    valid_task_name(task_name::String) :: String

Attempts to convert a potentially invalid (partial) `task_name` into a valid one.
"""
function valid_task_name(task_name::String) :: String
  task_name = replace(task_name, " "=>"_")
  task_name = Genie.Inflector.from_underscores(task_name)
  endswith(task_name, TASK_SUFFIX) || (task_name = task_name * TASK_SUFFIX)

  task_name
end


"""
    print_tasks() :: Nothing

Prints a list of all the registered Genie tasks to the standard output.
"""
function print_tasks() :: Nothing
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

  f = readdir(Genie.config.tasks_folder)
  for i in f
    if ( endswith(i, "Task.jl") )
      module_name = Genie.Util.file_name_without_extension(i) |> Symbol
      include(joinpath(Genie.config.tasks_folder, i))
      Core.eval(@__MODULE__, :(using .$(module_name)))
      ti = TaskInfo(i, module_name, task_docs(module_name))

      if ( filter_type_name == Symbol() ) push!(tasks, ti)
      elseif ( filter_type_name == module_name ) return TaskInfo[ti]
      end
    end
  end

  tasks
end
const all_tasks = tasks


"""
    task_docs(module_name::Module) :: String

Retrieves the docstring of the run_task method and returns it as a string.
"""
function task_docs(module_name::Symbol) :: String
  try
    docs = Base.doc(Base.Docs.Binding(getfield(@__MODULE__, module_name), :run_task)) |> string
    startswith(docs, "No documentation found") && (docs = "No documentation found -- add docstring to `$(module_name).run_task()` to see it here.")

    docs
  catch ex
    log(ex, :err)
    ""
  end
end


"""
    new(cmd_args::Dict{String,Any}, config::Settings) :: Nothing
    new(task_name::String, config::Settings = App.config) :: Nothing

Generates a new Genie task file.
"""
function new(cmd_args::Dict{String,Any}, config::Settings = Genie.config) :: Nothing
  tfn = task_file_name(cmd_args, config)

  if ispath(tfn)
    error("Task file already exists")
  end

  f = open(tfn, "w")
  write(f, Genie.FileTemplates.new_task(task_module_name(cmd_args["task:new"])))
  close(f)

  log("New task created at $tfn")

  nothing
end
function new(task_name::String, config::Settings = Genie.config) :: Nothing
  new(Dict{String,Any}("task:new" => valid_task_name(task_name)), config)
end


"""
    task_file_name(cmd_args::Dict{String,Any}, config::Settings) :: String

Computes the name of a Genie task based on the command line input.
"""
function task_file_name(cmd_args::Dict{String,Any}, config::Settings = Genie.config) :: String
  joinpath(config.tasks_folder, cmd_args["task:new"] * ".jl")
end


"""
    task_module_name(underscored_task_name::String) :: String

Computes the name of a Genie task based on the command line input.
"""
function task_module_name(underscored_task_name::String) :: String
  mapreduce( x -> uppercasefirst(x), *, split(replace(underscored_task_name, ".jl"=>""), "_") )
end


"""
    check_valid_task!(parsed_args::Dict{String,Any}) :: Dict{String,Any}

Checks if the name of the task passed as the command line arg is valid task identifier -- if not, attempts to address it, by appending the TASK_SUFFIX suffix.
Returns the potentially modified `parsed_args` `Dict`.
"""
function check_valid_task!(parsed_args::Dict{String,Any}) :: Dict{String,Any}
  haskey(parsed_args, "task:new") && isa(parsed_args["task:new"], String) && ! endswith(parsed_args["task:new"], TASK_SUFFIX) && (parsed_args["task:new"] *= TASK_SUFFIX)
  haskey(parsed_args, "task:run") && isa(parsed_args["task:run"], String) &&! endswith(parsed_args["task:run"], TASK_SUFFIX) && (parsed_args["task:run"] *= TASK_SUFFIX)

  parsed_args
end

end
