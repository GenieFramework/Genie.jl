"""
Compiled templating language for Genie.
"""
module Flax

import Revise
import SHA, Reexport, OrderedCollections, Logging, FilePaths
import Genie, Genie.Configuration
Reexport.@reexport using HttpCommon

export @foreach, @vars, @yield
export partial, template

import Base.string
import Base.show
import Base.==
import Base.hash


include("HTMLRenderer.jl")
using .HTMLRenderer

include("JSONRenderer.jl")
using .JSONRenderer

const BUILD_NAME    = "FlaxViews"


init_task_local_storage() = (haskey(task_local_storage(), :__vars) || task_local_storage(:__vars, Dict{Symbol,Any}()))
init_task_local_storage()

task_local_storage(:__yield, "")


"""
    partial(path::String; context::Module = @__MODULE__, vars...) :: String

Renders (includes) a view partial within a larger view or layout file.
"""
function partial(path::String; context::Module = @__MODULE__, vars...) :: String
  for (k,v) in vars
    try
      task_local_storage(:__vars)[k] = v
    catch
      init_task_local_storage()
      task_local_storage(:__vars)[k] = v
    end
  end

  template(path, partial = true, context = context)
end


"""
    parseview(data::String; partial = false, context::Module = @__MODULE__) :: Function

Parses a view file, returning a rendering function. If necessary, the function is JIT-compiled, persisted and loaded into memory.
"""
function parseview(data::String; partial = false, context::Module = @__MODULE__) :: Function
  data_hash = hash(data)
  path = "Flax_" * string(data_hash)

  func_name = function_name(string(data_hash, partial)) |> Symbol
  mod_name = m_name(string(path, partial)) * ".jl"
  f_path = joinpath(Genie.config.path_build, BUILD_NAME, mod_name)
  f_stale = build_is_stale(f_path, f_path)

  if f_stale || ! isdefined(context, func_name)
    f_stale && build_module(string_to_flax(data, partial = partial), path, mod_name)

    return Base.include(context, joinpath(Genie.config.path_build, BUILD_NAME, mod_name))
  end

  getfield(context, func_name)
end


"""
    template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: String

Renders a template file.
"""
@inline function template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: String
  HTMLRenderer.get_template(path, partial = partial, context = context) |> Base.invokelatest
end


"""
    build_is_stale(file_path::String, build_path::String) :: Bool

Checks if the view template has been changed since the last time the template was compiled.
"""
function build_is_stale(file_path::String, build_path::String) :: Bool
  isfile(file_path) || return true

  file_mtime = stat(file_path).mtime
  build_mtime = stat(build_path).mtime
  status = file_mtime > build_mtime

  Genie.config.log_views && status && @debug("🚨  Flax view $file_path build $build_path is stale")

  status
end


"""
    registervars(vars...) :: Nothing

Loads the rendering vars into the task's scope
"""
function registervars(vars...) :: Nothing
  init_task_local_storage()
  task_local_storage(:__vars, merge(Dict{Symbol,Any}(vars), task_local_storage(:__vars)))

  nothing
end


"""
    function_name(file_path::String)

Generates function name for generated Flax views.
"""
@inline function function_name(file_path::String) :: String
  "func_$(SHA.sha1(relpath(isempty(file_path) ? " " : file_path)) |> bytes2hex)"
end


"""
    m_name(file_path::String)

Generates module name for generated Flax views.
"""
@inline function m_name(file_path::String) :: String
  string(SHA.sha1(relpath(isempty(file_path) ? " " : file_path)) |> bytes2hex)
end


"""
    html_to_flax(file_path::String; partial = true) :: String

Converts a HTML document to a Flax document.
"""
@inline function html_to_flax(file_path::String; partial = true) :: String
  to_flax(file_path, parse_template, partial = partial)
end


"""
    string_to_flax(content::String; partial = true, f_name::Union{Symbol,Nothing} = nothing, prepend = "") :: String

Converts string view data to Flax code
"""
@inline function string_to_flax(content::String; partial = true, f_name::Union{Symbol,Nothing} = nothing, prepend = "") :: String
  to_flax(content, parse_string, partial = partial, f_name = f_name, prepend = prepend)
end


"""
    to_flax(input::String, f::Function; partial = true, f_name::Union{Symbol,Nothing} = nothing, prepend = "") :: String

Converts an input file to Flax code
"""
@inline function to_flax(input::String, f::Function; partial = true, f_name::Union{Symbol,Nothing} = nothing, prepend = "") :: String
  f_name = (f_name === nothing) ? function_name(string(input, partial)) : f_name

  string("function $(f_name)() \n",
          prepend,
          f(input, partial = partial),
          "\nend \n")
end


"""
    build_module(content::String, path::String, mod_name::String) :: String

Persists compiled Flax view data to file and returns the path
"""
function build_module(content::String, path::String, mod_name::String) :: String
  module_path = joinpath(Genie.config.path_build, BUILD_NAME, mod_name)

  isdir(dirname(module_path)) || mkpath(dirname(module_path))

  open(module_path, "w") do io
    write(io, "# $path \n\n")
    write(io, content)
  end

  module_path
end


"""
    read_template_file(file_path::String) :: String

Reads `file_path` template from disk.
"""
function read_template_file(file_path::String) :: String
  io = IOBuffer()
  open(file_path) do f
    for line in enumerate(eachline(f))
      print(io, parsetags(line), "\n")
    end
  end

  String(take!(io))
end


"""
    parse_template(file_path::String; partial = true) :: String

Parses a HTML file into Flax code.
"""
@inline function parse_template(file_path::String; partial::Bool = true) :: String
  parse(read_template_file(file_path), partial = partial)
end


"""
    parse_string(data::String; partial = true) :: String

Parses a HTML string into Flax code.
"""
@inline function parse_string(data::String; partial::Bool = true) :: String
  parse(parsetags(data), partial = partial)
end


@inline function parse(input::String; partial::Bool = true) :: String
  HTMLRenderer.parsehtml(input, partial = partial)
end


"""
    parsetags(line::Tuple{Int64,String}, strip_close_tag = false) :: String

Parses special Flax tags.
"""
@inline function parsetags(line::Tuple{Int64,String}) :: String
  parsetags(line[2])
end
@inline function parsetags(code::String) :: String
  code = replace(code, "<%"=>"""<script type="julia/eval">""")
  replace(code, "%>"=>"""</script>""")
end


"""
    register_elements() :: Nothing

Generated functions that represent Flax functions definitions corresponding to HTML elements.
"""
@inline function register_elements() :: Nothing
  for elem in HTMLRenderer.NORMAL_ELEMENTS
    register_normal_element(elem)
  end

  for elem in HTMLRenderer.VOID_ELEMENTS
    register_void_element(elem)
  end

  nothing
end


@inline function register_element(elem::Symbol, elem_type::Symbol = :normal) :: Nothing
  elem_type == :normal ? register_normal_element(elem) : register_void_element(elem)
end


function register_normal_element(elem::Symbol) :: Nothing
  Core.eval(@__MODULE__, """
    function $elem(f::Function, args...; attrs...) :: HTMLString
      \"\"\"\$(HTMLRenderer.normal_element(f, "$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)
  Core.eval(@__MODULE__, """
    function $elem(children::Union{String,Vector{String}} = "", args...; attrs...) :: HTMLString
      \"\"\"\$(HTMLRenderer.normal_element(children, "$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  nothing
end


function register_void_element(elem::Symbol) :: Nothing
  Core.eval(@__MODULE__, """
    function $elem(args...; attrs...) :: HTMLString
      \"\"\"\$(HTMLRenderer.void_element("$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  nothing
end


"""
    @foreach(f, arr)

Iterates over the `arr` Array and applies function `f` for each element.
The results of each iteration are concatenated and the final string is returned.

## Examples

@foreach(@vars(:translations)) do t
  t
end
"""
macro foreach(f, arr)
  quote
    isempty($(esc(arr))) && return ""

    mapreduce(*, $(esc(arr))) do _s
      $f(_s) * "\n"
    end
  end
end


register_elements()


"""
    @vars

Utility macro for accessing view vars
"""
macro vars()
  :(task_local_storage(:__vars))
end


"""
    @vars(key)

Utility macro for accessing view vars stored under `key`
"""
macro vars(key)
  :(task_local_storage(:__vars)[$key])
end


"""
    @vars(key, value)

Utility macro for setting a new view var, as `key` => `value`
"""
macro vars(key, value)
  quote
    try
      task_local_storage(:__vars)[$key] = $(esc(value))
    catch
      init_task_local_storage()
      task_local_storage(:__vars)[$key] = $(esc(value))
    end
  end
end


"""
    @yield

Outputs the rendering of the view within the template.
"""
macro yield()
  quote
    try
      task_local_storage(:__yield)
    catch
      task_local_storage(:__yield, "")
    end
  end
end
macro yield(value)
  :(task_local_storage(:__yield, $value))
end

function el(; vars...)
  OrderedCollections.OrderedDict(vars)
end


"""
    prepare_build() :: Bool

Sets up the build folder and the build module file for generating the compiled views.
"""
function prepare_build(subfolder = BUILD_NAME) :: Bool
  build_path = joinpath(Genie.config.path_build, subfolder)

  Genie.Configuration.@ifdev rm(build_path, force = true, recursive = true)
  if ! isdir(build_path)
    @info "Creating build folder at $(build_path)"
    mkpath(build_path)
  end

  true
end

end