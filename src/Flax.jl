"""
Compiled templating language for Genie.
"""
module Flax

import Revise
import Gumbo, SHA, Reexport, OrderedCollections, Logging, FilePaths
import Genie, Genie.Configuration
Reexport.@reexport using HttpCommon

export @foreach, @vars, @yield
export partial, template

import Base.string
import Base.show
import Base.==
import Base.hash


const NORMAL_ELEMENTS = [ :html, :head, :body, :title, :style, :address, :article, :aside, :footer,
                          :header, :h1, :h2, :h3, :h4, :h5, :h6, :hgroup, :nav, :section,
                          :dd, :div, :d, :dl, :dt, :figcaption, :figure, :li, :main, :ol, :p, :pre, :ul, :span,
                          :a, :abbr, :b, :bdi, :bdo, :cite, :code, :data, :dfn, :em, :i, :kbd, :mark,
                          :q, :rp, :rt, :rtc, :ruby, :s, :samp, :small, :spam, :strong, :sub, :sup, :time,
                          :u, :var, :wrb, :audio, :map, :void, :embed, :object, :canvas, :noscript, :script,
                          :del, :ins, :caption, :col, :colgroup, :table, :tbody, :td, :tfoot, :th, :thead, :tr,
                          :button, :datalist, :fieldset, :form, :label, :legend, :meter, :optgroup, :option,
                          :output, :progress, :select, :textarea, :details, :dialog, :menu, :menuitem, :summary,
                          :slot, :template, :blockquote, :center]
const VOID_ELEMENTS   = [:base, :link, :meta, :hr, :br, :area, :img, :track, :param, :source, :input]
const BOOL_ATTRIBUTES = [:checked, :disabled, :selected]


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
  f_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, mod_name)
  f_stale = build_is_stale(f_path, f_path)

  if f_stale || ! isdefined(context, func_name)
    f_stale && build_module(string_to_flax(data, partial = partial), path, mod_name)

    return Base.include(context, joinpath(Genie.BUILD_PATH, BUILD_NAME, mod_name))
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
  "func_$(SHA.sha1(relpath(file_path)) |> bytes2hex)"
end


"""
    m_name(file_path::String)

Generates module name for generated Flax views.
"""
@inline function m_name(file_path::String) :: String
  string(SHA.sha1(relpath(file_path)) |> bytes2hex)
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
  f_name = f_name === nothing ? function_name(input) : f_name

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
  module_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, mod_name)

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
@inline function parse_template(file_path::String; partial = true) :: String
  parse(read_template_file(file_path), partial = partial)
end


"""
    parse_string(data::String; partial = true) :: String

Parses a HTML string into Flax code.
"""
@inline function parse_string(data::String; partial = true) :: String
  parse(parsetags(data), partial = partial)
end


@inline function parse(input::String; partial = true) :: String
  parsetree(Gumbo.parsehtml(input).root, "", 0, partial = partial)
end


"""
    parsetree(elem, output, depth; partial = true) :: String

Parses a Gumbo tree structure into a `string` of Flax code.
"""
function parsetree(elem::Union{Gumbo.HTMLElement,Gumbo.HTMLText}, output::String = "", depth::Int = 0; partial = true) :: String
  io = IOBuffer()

  if isa(elem, Gumbo.HTMLElement)
    tag_name = replace(lowercase(string(Gumbo.tag(elem))), "-"=>"_")

    if Genie.config.flax_autoregister_webcomponents && ! isdefined(@__MODULE__, Symbol(tag_name))
      @debug "Autoregistering HTML element $tag_name"

      register_element(Symbol(tag_name))
      print(io, "Genie.Flax.register_element(Symbol(\"$tag_name\")) \n")
    end

    invalid_tag = partial && (tag_name == "html" || tag_name == "head" || tag_name == "body")

    if tag_name == "script" && in("type", collect(keys(Gumbo.attrs(elem))))
      if Gumbo.attrs(elem)["type"] == "julia/eval"
        if ! isempty(Gumbo.children(elem))
          print(io, repeat("\t", depth), string(Gumbo.children(elem)[1].text), "\n")
        end
      end

    else
      print(io, repeat("\t", depth), ( ! invalid_tag ? "Html.$(tag_name)(" : "Html.HTMLRenderer.skip_element(" ))

      attributes = IOBuffer()
      for (k,v) in Gumbo.attrs(elem)
        x = v

        if startswith(k, "\$") # do not process embedded julia code
          print(attributes, string(k)[2:end], ", ") # strip the $, this is rendered directly in Julia code
          continue
        end

        if in(Symbol(lowercase(k)), BOOL_ATTRIBUTES)
          if x == true || x == "true" || x == :true || x == ":true" || x == "" || x == "on"
            print(attributes, "$k=\"$k\"", ", ") # boolean attributes can have the same value as the attribute -- or be empty
          end
        else
          print(attributes, """$(replace(lowercase(string(k)), "-"=>"_"))="$v" """, ", ")
        end
      end

      attributes_string = String(take!(attributes))
      endswith(attributes_string, ", ") && (attributes_string = attributes_string[1:end-2])
      print(io, attributes_string, ") ")

      inner = ""
      if ! isempty(Gumbo.children(elem))
        children_count = size(Gumbo.children(elem))[1]

        print(io, "do;[\n")

        idx = 0
        for child in Gumbo.children(elem)
          idx += 1
          inner *= parsetree(child, "", depth + 1, partial = partial)
          if idx < children_count
            if isa(child, Gumbo.HTMLText) ||
                ( isa(child, Gumbo.HTMLElement) && ( ! in("type", collect(keys(Gumbo.attrs(child)))) ||
                  ( in("type", collect(keys(Gumbo.attrs(child)))) && (Gumbo.attrs(child)["type"] != "julia/eval") ) ) )
                ! isempty(inner) && (inner = repeat("\t", depth) * inner * "\n")
            end
          end
        end
        isempty(inner) || (print(io, inner, "\n", repeat("\t", depth)))

        print(io, "]end\n")
      end
    end

  elseif isa(elem, Gumbo.HTMLText)
    content = elem.text # |> strip |> string
    endswith(content, "\"") && (content *= "\n")
    print(io, repeat("\t", depth), "\"\"\"$(content)\"\"\"")
  end

  String(take!(io))
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
  for elem in NORMAL_ELEMENTS
    register_normal_element(elem)
  end

  for elem in VOID_ELEMENTS
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
    vardump(var, html = true) :: String

Utility function for dumping a variable into the view.
"""
function vardump(var, html = true) :: String
  iobuffer = IOBuffer()
  show(iobuffer, var)
  content = String(take!(iobuffer))

  html ? replace(replace("<code>$content</code>", "\n"=>"<br>"), " "=>"&nbsp;") : content
end


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
function prepare_build(subfolder) :: Bool
  build_path = joinpath(Genie.BUILD_PATH, subfolder)

  Genie.Configuration.@ifdev rm(build_path, force = true, recursive = true)
  if ! isdir(build_path)
    @info "Creating build folder at $(build_path)"
    mkpath(build_path)
  end

  true
end


"""
    create_build_folders()

Sets up build folders.
"""
@inline function create_build_folders()
  prepare_build(BUILD_NAME)
end

end