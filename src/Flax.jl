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

const Html = @__MODULE__
const BUILD_NAME = "FlaxViews"

const Path = FilePaths.Path
const FilePath = Union{FilePaths.PosixPath,FilePaths.WindowsPath}
const filepath = FilePaths.Path

include("HTMLRenderer.jl")
using .HTMLRenderer

include("JSONRenderer.jl")
using .JSONRenderer

include("JSRenderer.jl")
using .JSRenderer


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
    template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: String

Renders a template file.
"""
@inline function template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: String
  Base.invokelatest(HTMLRenderer.get_template(path, partial = partial, context = context))::String
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
@inline function registervars(vars...) :: Nothing
  init_task_local_storage()
  task_local_storage(:__vars, merge(task_local_storage(:__vars), Dict{Symbol,Any}(vars)))

  nothing
end


@inline function vars_signature() :: String
  task_local_storage(:__vars) |> keys |> collect |> sort |> string
end


"""
    function_name(file_path::String)

Generates function name for generated Flax views.
"""
@inline function function_name(file_path::String) :: String
  "func_$(SHA.sha1( relpath(isempty(file_path) ? " " : file_path) * vars_signature() ) |> bytes2hex)"
end


"""
    m_name(file_path::String)

Generates module name for generated Flax views.
"""
@inline function m_name(file_path::String) :: String
  string(SHA.sha1( relpath(isempty(file_path) ? " " : file_path) * vars_signature()) |> bytes2hex)
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
@inline function to_flax(input::String, f::Function; partial = true, f_name::Union{Symbol,Nothing} = nothing, prepend = "\n") :: String
  f_name = (f_name === nothing) ? function_name(string(input, partial)) : f_name

  string("function $(f_name)() \n",
          injectvars(),
          prepend,
          f(input, partial = partial),
          "\nend \n")
end


function injectvars() :: String
  output = ""
  for kv in task_local_storage(:__vars)
    output *= "$(kv[1]) = @vars($(repr(kv[1]))) \n"
  end

  output
end


function injectvars(context::Module) :: Nothing
  for kv in task_local_storage(:__vars)
    # isdefined(context, Symbol(kv[1])) ||
    Core.eval(context, Meta.parse("$(kv[1]) = @vars($(repr(kv[1])))"))
  end

  nothing
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
    parsetags(line::Tuple{Int,String}, strip_close_tag = false) :: String

Parses special Flax tags.
"""
@inline function parsetags(line::Tuple{Int,String}) :: String
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


@inline function register_element(elem::Union{Symbol,String}, elem_type::Union{Symbol,String} = :normal; context = Flax) :: Nothing
  elem = string(elem)
  occursin('-', elem) && (elem = HTMLRenderer.denormalize_element(elem))

  elem_type == :normal ? register_normal_element(elem) : register_void_element(elem)
end


function register_normal_element(elem::Union{Symbol,String}; context = Flax) :: Nothing
  Core.eval(context, """
    function $elem(f::Function, args...; attrs...) :: HTMLString
      \"\"\"\$(HTMLRenderer.normal_element(f, "$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  Core.eval(context, """
    function $elem(children::Union{String,Vector{String}} = "", args...; attrs...) :: HTMLString
      \"\"\"\$(HTMLRenderer.normal_element(children, "$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  nothing
end


function register_void_element(elem::Union{Symbol,String}; context = Flax) :: Nothing
  Core.eval(context, """
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
  e = quote
    isempty($(esc(arr))) && return ""

    mapreduce(*, $(esc(arr))) do _s
      $(esc(f))(_s)
    end
  end

  quote
    Core.eval($__module__, $e)
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
    preparebuilds() :: Bool

Sets up the build folder and the build module file for generating the compiled views.
"""
function preparebuilds(subfolder = BUILD_NAME) :: Bool
  build_path = joinpath(Genie.config.path_build, subfolder)
  isdir(build_path) || mkpath(build_path)

  true
end


function purgebuilds(subfolder = BUILD_NAME) :: Bool
  rm(joinpath(Genie.config.path_build, subfolder), force = true, recursive = true)

  true
end


function changebuilds(subfolder = BUILD_NAME) :: Bool
  Genie.config.path_build = Genie.Configuration.buildpath()
  preparebuilds()
end


"""
    view_file_info(path::String, supported_extensions = SUPPORTED_HTML_OUTPUT_FILE_FORMATS) :: Tuple{String,String}

Extracts path and extension info about a file
"""
function view_file_info(path::String, supported_extensions::Vector{String} = HTMLRenderer.SUPPORTED_HTML_OUTPUT_FILE_FORMATS) :: Tuple{String,String}
  _path, _extension = "", ""

  if isfile(path)
    _path, _extension = relpath(path), "." * split(path, ".", limit = 2)[end]
  else
    for file_extension in supported_extensions
      if isfile(path * file_extension)
        _path, _extension = path * file_extension, file_extension
        break
      end
    end
  end

  _path, _extension
end

end