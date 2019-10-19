"""
Compiled templating language for Genie.
"""
module Flax

import Revise, Gumbo, SHA, Reexport, JSON, OrderedCollections, Markdown, YAML, Logging
import Genie, Genie.Configuration
Reexport.@reexport using HttpCommon

export HTMLString, JSONString, JSString
export doctype, vardump, el
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

const FILE_EXT      = [".flax.jl", "html.jl"]
const TEMPLATE_EXT  = [".flax.html", ".jl.html"]
const JSON_FILE_EXT = ".json.jl"
const MARKDOWN_FILE_EXT = [".md", ".jl.md"]

const SUPPORTED_HTML_OUTPUT_FILE_FORMATS = TEMPLATE_EXT

const HTMLString = String
const JSONString = String

const BUILD_NAME    = "FlaxViews"

const MD_SEPARATOR_START = "---\n"
const MD_SEPARATOR_END   = "---\n"


init_task_local_storage() = (haskey(task_local_storage(), :__vars) || task_local_storage(:__vars, Dict{Symbol,Any}()))
init_task_local_storage()

task_local_storage(:__yield, "")


"""
    prepare_template(s::String)
    prepare_template{T}(v::Vector{T})

Cleans up the template before rendering (ex by removing empty nodes).
"""
@inline function prepare_template(s::String) :: String
  s
end
@inline function prepare_template(v::Vector{T})::String where {T}
  filter!(v) do (x)
    ! isa(x, Nothing)
  end

  join(v)
end


"""
    attributes(attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: Vector{String}

Parses HTML attributes.
"""
function attributes(attrs::Vector{Pair{Symbol,Any}} = Vector{Pair{Symbol,Any}}()) :: String
  a = IOBuffer()

  for (k,v) in attrs
    sk = string(k)
    sk == "typ" && (k = "type")
    startswith(sk, "_") && (k = sk = sk[2:end])
    k = replace(sk, "_"=>"-")

    print(a, "$(k)=\"$(v)\" ")
  end

  String(take!(a))
end


"""
    normalize_element(elem::String)

Cleans up problematic characters or DOM elements.
"""
@inline function normalize_element(elem::String)
  elem == "d" && (elem = "div")
  replace(string(lowercase(elem)), "_"=>"-")
end


"""
    normal_element(f::Function, elem::String, attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString

Generates a HTML element in the form <...></...>
"""
@inline function normal_element(f::Function, elem::String, args = [], attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  normal_element(f(), elem, args, attrs...)
end
@inline function normal_element(children::Union{String,Vector{String}}, elem::String, args, attrs::Pair{Symbol,Any}) :: HTMLString
  normal_element(children, elem, args, Pair{Symbol,Any}[attrs])
end
@inline function normal_element(children::Union{String,Vector{String}}, elem::String, args, attrs...) :: HTMLString
  normal_element(children, elem, args, Pair{Symbol,Any}[attrs...])
end
@inline function normal_element(children::Union{String,Vector{String}}, elem::String, args = [], attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  children = join(children)
  elem = normalize_element(elem)
  attribs = rstrip(attributes(attrs))
  string("<", elem, (isempty(attribs) ? "" : " $attribs"), (isempty(args) ? "" : " $(join(args, " "))"), ">", prepare_template(children), "</", elem, ">")
end
@inline function normal_element(elem::String, attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  normal_element("", elem, attrs...)
end
@inline function normal_element(elems::Vector, elem::String, args = [], attrs...) :: HTMLString
  io = IOBuffer()

  for e in elems
    e === nothing && continue

    if isa(e, Function)
      print(io, e(), "\n")
    else
      print(io, e, "\n")
    end
  end

  normal_element(String(take!(io)), elem, args, attrs...)
end
@inline function normal_element(_::Nothing, __::Any) :: HTMLString
  ""
end


"""
    void_element(elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString

Generates a void HTML element in the form <...>
"""
@inline function void_element(elem::String, args = [], attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  attribs = rstrip(attributes(attrs))
  string("<", normalize_element(elem), (isempty(attribs) ? "" : " $attribs"), (isempty(args) ? "" : " $(join(args, " "))"), ">")
end


"""
    skip_element(f::Function) :: HTMLString
    skip_element() :: HTMLString

Cleans up empty elements.
"""
@inline function skip_element(f::Function) :: HTMLString
  "$(prepare_template(f()))"
end
@inline function skip_element() :: HTMLString
  ""
end


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
    view_file_info(path::String) :: Tuple{String,String}

Extracts path and extension info about a file
"""
function view_file_info(path::String) :: Tuple{String,String}
  _path, _extension = "", ""

  if isfile(path)
    _path, _extension = relpath(path), "." * split(path, ".", limit = 2)[end]
  else
    for file_extension in SUPPORTED_HTML_OUTPUT_FILE_FORMATS
      if isfile(path * file_extension)
        _path, _extension = path * file_extension, file_extension
        break
      end
    end
  end

  _path, _extension
end


"""
    include_markdown(path::String; context::Module = @__MODULE__)

Includes and renders a markdown view file
"""
function include_markdown(path::String; context::Module = @__MODULE__)
  md = read(path, String)

  vars_injection = ""

  if startswith(md, MD_SEPARATOR_START)
    close_sep_pos = findfirst(MD_SEPARATOR_END, md[length(MD_SEPARATOR_START)+1:end])
    metadata = md[length(MD_SEPARATOR_START)+1:close_sep_pos[end]] |> YAML.load

    vars_injection = ""
    for (k,v) in metadata
      task_local_storage(:__vars)[Symbol(k)] = v
      vars_injection *= """@vars($(repr(Symbol(k)))) = $(v)\n"""
    end

    md = replace(md[close_sep_pos[end]+length(MD_SEPARATOR_END)+1:end], "\"\"\""=>"\\\"\\\"\\\"")
  end

  content = string( "\"\"\"", md, "\"\"\"")

  vars_injection, (include_string(context, content) |> Markdown.parse |> Markdown.html)
end


"""
    get_template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: Function

Resolves the inclusion and rendering of a template file
"""
function get_template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: Function
  orig_path = path

  path, extension = view_file_info(path)

  isfile(path) || error("Template file $orig_path does not exist")

  extension in FILE_EXT && return (() -> Base.include(context, path))

  f_name = Symbol(function_name(path))
  f_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl")
  f_stale = build_is_stale(path, f_path)

  if f_stale || ! isdefined(context, f_name)
    content = if extension in MARKDOWN_FILE_EXT
      vars_injection, md = include_markdown(path, context = context)
      string_to_flax(md, partial = partial, f_name = f_name, prepend = vars_injection)
    else
      html_to_flax(path, partial = partial)
    end

    f_stale && build_module(content, path)

    return Base.include(context, joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl"))
  end

  getfield(context, f_name)
end


"""
    parse_view(data::String; partial = false, context::Module = @__MODULE__) :: Function

Parses a view file, returning a rendering function. If necessary, the function is JIT-compiled, persisted and loaded into memory.
"""
function parse_view(data::String; partial = false, context::Module = @__MODULE__) :: Function
  path = "Flax_" * string(hash(data))

  func_name = function_name(data) |> Symbol
  f_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl")
  f_stale = build_is_stale(f_path, f_path)

  if f_stale || ! isdefined(context, func_name)
    f_stale && build_module(string_to_flax(data, partial = partial), path)

    return Base.include(context, joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl"))
  end

  getfield(context, func_name)
end


"""
    template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: String

Renders a template file.
"""
@inline function template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: String
  get_template(path, partial = partial, context = context) |> Base.invokelatest
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
    register_vars(vars...) :: Nothing

Loads the rendering vars into the task's scope
"""
@inline function register_vars(vars...) :: Nothing
  init_task_local_storage()
  task_local_storage(:__vars, merge(Dict{Symbol,Any}(vars), task_local_storage(:__vars)))

  nothing
end


"""
    html_renderer(resource::Union{Symbol,String}, action::Union{Symbol,String}; layout::Union{Symbol,String} = Genie.config.renderer_default_layout_file, context::Module = @__MODULE__, vars...) :: Function

Renders data as HTML
"""
function html_renderer(resource::Union{Symbol,String}, action::Union{Symbol,String}; layout::Union{Symbol,String} = Genie.config.renderer_default_layout_file, context::Module = @__MODULE__, vars...) :: Function
  register_vars(vars...)
  task_local_storage(:__yield, get_template(joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action)), partial = true, context = context) |> Base.invokelatest)

  layout = Base.get(task_local_storage(:__vars), :layout, layout)

  get_template(joinpath(Genie.APP_PATH, Genie.LAYOUTS_FOLDER, string(layout)), partial = false, context = context)
end
function html_renderer(data::String; context::Module = @__MODULE__, layout::Union{Symbol,String,Nothing} = nothing, vars...) :: Function
  register_vars(vars...)

  if layout != nothing
    task_local_storage(:__yield, parse_view(data, partial = true, context = context))
    get_template(joinpath(Genie.APP_PATH, Genie.LAYOUTS_FOLDER, string(layout)), partial = false, context = context)
  else
    parse_view(data, partial = false, context = context)
  end
end


"""
    json_renderer(resource::Union{Symbol,String}, action::Union{Symbol,String}; context::Module = @__MODULE__, vars...) :: Function

Renders data as JSON
"""
@inline function json_renderer(resource::Union{Symbol,String}, action::Union{Symbol,String}; context::Module = @__MODULE__, vars...) :: Function
  register_vars(vars...)

    () -> (Base.include(context, joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action) * JSON_FILE_EXT)) |> JSON.json)
end


"""
    function_name(file_path::String)

Generates function name for generated Flax views.
"""
@inline function function_name(file_path::String) :: String
  file_path = relpath(file_path)
  "func_$(SHA.sha1(file_path) |> bytes2hex)"
end


"""
    m_name(file_path::String)

Generates module name for generated Flax views.
"""
@inline function m_name(file_path::String) :: String
  file_path = relpath(file_path)
  "$(SHA.sha1(file_path) |> bytes2hex)"
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
    build_module(content::String, path::String) :: Bool

Persists compiled Flax view data to file
"""
function build_module(content::String, path::String) :: Bool
  module_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl")
  isdir(joinpath(Genie.BUILD_PATH, BUILD_NAME)) || mkpath(joinpath(Genie.BUILD_PATH, BUILD_NAME))
  open(module_path, "w") do io
    write(io, "# $path \n\n")
    write(io, content)
  end

  true
end


"""
    read_template_file(file_path::String) :: String

Reads `file_path` template from disk.
"""
function read_template_file(file_path::String) :: String
  io = IOBuffer()
  open(file_path) do f
    for line in enumerate(eachline(f))
      print(io, parse_tags(line), "\n")
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
  parse(parse_tags(data), partial = partial)
end


@inline function parse(input::String; partial = true) :: String
  parse_tree(Gumbo.parsehtml(input).root, "", 0, partial = partial)
end


"""
    parse_tree(elem, output, depth; partial = true) :: String

Parses a Gumbo tree structure into a `string` of Flax code.
"""
function parse_tree(elem::Union{Gumbo.HTMLElement,Gumbo.HTMLText}, output::String = "", depth::Int = 0; partial = true) :: String
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
      print(io, repeat("\t", depth), ( ! invalid_tag ? "Flax.$(tag_name)(" : "Flax.skip_element(" ))

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
          inner *= parse_tree(child, "", depth + 1, partial = partial)
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
    content = elem.text |> strip |> string
    endswith(content, "\"") && (content *= "\n")
    print(io, repeat("\t", depth), "\"\"\"$(content)\"\"\"")
  end

  String(take!(io))
end


"""
    parse_tags(line::Tuple{Int64,String}, strip_close_tag = false) :: String

Parses special Flax tags.
"""
@inline function parse_tags(line::Tuple{Int64,String}) :: String
  parse_tags(line[2])
end
@inline function parse_tags(code::String) :: String
  code = replace(code, "<%"=>"""<script type="julia/eval">""")
  replace(code, "%>"=>"""</script>""")
end


"""
Outputs document's doctype.
"""
@inline function doctype(doctype::Symbol = :html) :: HTMLString
  "<!DOCTYPE $doctype>"
end


"""
Outputs document's doctype.
"""
@inline function doc(html::String) :: HTMLString
  doctype() * "\n" * html
end
@inline function doc(doctype::Symbol, html::String) :: HTMLString
  doctype(doctype) * "\n" * html
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
      \"\"\"\$(normal_element(f, "$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)
  Core.eval(@__MODULE__, """
    function $elem(children::Union{String,Vector{String}} = "", args...; attrs...) :: HTMLString
      \"\"\"\$(normal_element(children, "$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  nothing
end


function register_void_element(elem::Symbol) :: Nothing
  Core.eval(@__MODULE__, """
    function $elem(args...; attrs...) :: HTMLString
      \"\"\"\$(void_element("$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  nothing
end

push!(LOAD_PATH,  abspath(Genie.HELPERS_PATH))


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