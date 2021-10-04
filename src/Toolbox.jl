module Toolbox
using DocStringExtensionsMock

import Base.string

import Inflector
import Genie, Genie.Util, Millboard, Genie.FileTemplates, Genie.Configuration, Genie.Exceptions, Logging

export TaskResult, VoidTaskResult

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
$TYPEDSIGNATURES

Returns a vector of all registered Genie tasks.
"""
function tasks(context::Module; filter_type_name::Union{Symbol,Nothing} = nothing) :: Vector{TaskInfo}
  tasks = TaskInfo[]

  f = readdir(joinpath(Main.UserApp.ROOT_PATH, Genie.config.path_tasks))

  for i in f
    if ( endswith(i, "Task.jl") )
      module_name = Genie.Util.file_name_without_extension(i) |> Symbol
      Core.eval(context, :(include(joinpath(Genie.config.path_tasks, $i))))
      Core.eval(context, :(using .$(module_name)))

      ti = TaskInfo(i, module_name, taskdocs(module_name, context = context))

      if ( filter_type_name === nothing ) push!(tasks, ti)
      elseif ( filter_type_name == module_name ) return TaskInfo[ti]
      end
    end
  end

  tasks
end
const loadtasks = tasks


"""
$TYPEDSIGNATURES
"""
function VoidTaskResult()
  TaskResult(0, "", nothing)
end


"""
$TYPEDSIGNATURES

Attempts to convert a potentially invalid (partial) `task_name` into a valid one.
"""
function validtaskname(task_name::String) :: String
  task_name = replace(task_name, " "=>"_")
  task_name = Inflector.from_underscores(task_name)
  endswith(task_name, TASK_SUFFIX) || (task_name = task_name * TASK_SUFFIX)

  task_name
end


"""
$TYPEDSIGNATURES

Prints a list of all the registered Genie tasks to the standard output.
"""
function printtasks(context::Module) :: Nothing
  output = ""
  arr_output = []
  for t in tasks(context)
    td = Genie.to_dict(t)
    push!(arr_output, [td["module_name"], td["file_name"], td["description"]])
  end

  Millboard.table(arr_output, colnames = ["Task name \nFilename \nDescription "], rownames = []) |> println
end


"""
$TYPEDSIGNATURES

Retrieves the docstring of the runtask method and returns it as a string.
"""
function taskdocs(module_name::Symbol; context = @__MODULE__) :: String
  try
    docs = Base.doc(Base.Docs.Binding(getfield(context, module_name), :runtask)) |> string
    startswith(docs, "No documentation found") && (docs = "No documentation found -- add docstring to `$(module_name).runtask()` to see it here.")

    docs
  catch ex
    @error ex
    ""
  end
end


"""
$TYPEDSIGNATURES

Generates a new Genie task file.
"""
function new(task_name::String) :: Nothing
  task_name = validtaskname(task_name)
  tfn = taskfilename(task_name)

  isfile(tfn) && throw(Genie.Exceptions.FileExistsException(tfn))
  isdir(Genie.config.path_tasks) || mkpath(Genie.config.path_tasks)

  open(tfn, "w") do io
    write(io, Genie.FileTemplates.newtask(taskmodulename(task_name)))
  end

  @info "New task created at $tfn"

  nothing
end


"""
$TYPEDSIGNATURES

Computes the name of a Genie task based on the command line input.
"""
function taskfilename(task_name::String) :: String
  joinpath(Genie.config.path_tasks, "$task_name.jl")
end


"""
$TYPEDSIGNATURES

Computes the name of a Genie task based on the command line input.
"""
function taskmodulename(underscored_task_name::String) :: String
  mapreduce( x -> uppercasefirst(x), *, split(replace(underscored_task_name, ".jl"=>""), "_") )
end


"""
$TYPEDSIGNATURES

Checks if the name of the task passed as the command line arg is valid task identifier -- if not, attempts to address it, by appending the TASK_SUFFIX suffix.
Returns the potentially modified `parsed_args` `Dict`.
"""
function isvalidtask!(parsed_args::Dict{String,Any}) :: Dict{String,Any}
  haskey(parsed_args, "task:new") && isa(parsed_args["task:new"], String) && ! endswith(parsed_args["task:new"], TASK_SUFFIX) && (parsed_args["task:new"] *= TASK_SUFFIX)
  haskey(parsed_args, "task:run") && isa(parsed_args["task:run"], String) &&! endswith(parsed_args["task:run"], TASK_SUFFIX) && (parsed_args["task:run"] *= TASK_SUFFIX)

  parsed_args
end

end