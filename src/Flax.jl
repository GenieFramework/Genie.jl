"""
Compiled templating language for Genie.
"""
module Flax

using Revise, Gumbo, SHA, Reexport, JSON, OrderedCollections, Markdown, YAML
using Genie, Genie.Loggers, Genie.Configuration
@reexport using HttpCommon

export HTMLString, JSONString, JSString
export doctype, var_dump, @vars, @yield, el
export foreachvar, @foreach, foreachstr
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
function prepare_template(s::String) :: String
  s
end
function prepare_template(v::Vector{T})::String where {T}
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
"""
function normalize_element(elem::String)
  elem == "d" && (elem = "div")
  replace(string(lowercase(elem)), "_"=>"-")
end


"""
    normal_element(f::Function, elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString

Generates a regular HTML element in the form <...></...>
"""
function normal_element(f::Function, elem::String, attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  normal_element(f(), elem, attrs...)
end
function normal_element(children::Union{String,Vector{String}}, elem::String, attrs::Pair{Symbol,Any}) :: HTMLString
  normal_element(children, elem, Pair{Symbol,Any}[attrs])
end
function normal_element(children::Union{String,Vector{String}}, elem::String, attrs...) :: HTMLString
  normal_element(children, elem, Pair{Symbol,Any}[attrs...])
end
function normal_element(children::Union{String,Vector{String}}, elem::String, attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  children = join(children)
  elem = normalize_element(elem)

  string("<", elem, " ", attributes(attrs), ">", prepare_template(children), "</", elem, ">")
end
function normal_element(elem::String, attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  normal_element("", elem, attrs...)
end
function normal_element(elems::Vector, elem::String) :: HTMLString
  io = IOBuffer()

  for e in elems
    if isa(e, Function)
      print(io, e(), "\n")
    else
      print(io, e, "\n")
    end
  end

  normal_element(String(take!(io)), elem)
end
function normal_element(_::Nothing, __::Any) :: HTMLString
  ""
end


"""
    void_element(elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString

Generates a void HTML element in the form <...>
"""
function void_element(elem::String, attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  string("<", normalize_element(elem), " ", attributes(attrs), ">")
end


"""
    skip_element(f::Function) :: HTMLString
    skip_element() :: HTMLString

Cleans up empty elements.
"""
function skip_element(f::Function) :: HTMLString
  "$(prepare_template(f()))"
end
function skip_element() :: HTMLString
  ""
end


"""
"""
function partial(path::String; mod::Module = @__MODULE__, vars...) :: String
  for (k,v) in vars
    if k == :context && isa(v, Module)
      (mod = v)
      continue
    end

    try
      task_local_storage(:__vars)[k] = v
    catch
      init_task_local_storage()
      task_local_storage(:__vars)[k] = v
    end
  end

  template(path, partial = true, mod = mod)
end


"""
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
"""
function include_markdown(path::String; mod::Module = @__MODULE__)
  md = read(path, String)

  if startswith(md, MD_SEPARATOR_START)
    close_sep_pos = findfirst(MD_SEPARATOR_END, md[length(MD_SEPARATOR_START)+1:end])
    metadata = md[length(MD_SEPARATOR_START)+1:close_sep_pos[end]] |> YAML.load

    vars_injection = ""
    for (k,v) in metadata
      task_local_storage(:__vars)[Symbol(k)] = v
      vars_injection *= "\$( @vars($(repr(Symbol(k)))) = $(repr(MIME("text/html"), v)) ) \n"
    end

    md = md[close_sep_pos[end]+length(MD_SEPARATOR_END)+1:end]

    # TODO: escape 3 quotes
  end

  content = string( "\"\"\"", md, "\"\"\"")

  vars_injection * (include_string(mod, content) |> Markdown.parse |> Markdown.html)
end


function get_template(path::String; partial::Bool = true, mod::Module = @__MODULE__) :: Function
  path, extension = view_file_info(path)

  extension in FILE_EXT && return (() -> Base.include(mod, path))

  f_name = Symbol(function_name(path))
  f_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl")
  f_stale = build_is_stale(path, f_path)

  if f_stale || ! isdefined(mod, f_name)
    content = if extension in MARKDOWN_FILE_EXT
      md = include_markdown(path, mod = mod)
      @show md
      string_to_flax(md, partial = partial, f_name = f_name)
    else
      html_to_flax(path, partial = partial)
    end

    f_stale && build_module(content, path)

    return Base.include(mod, joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl"))
  end

  getfield(mod, f_name)
end


"""
"""
function parse_view(data::String; partial = false, mod::Module = @__MODULE__) :: Function
  path = "Flax_" * string(hash(data))

  func_name = function_name(data) |> Symbol
  f_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl")
  f_stale = build_is_stale(f_path, f_path)

  if f_stale || ! isdefined(mod, func_name)
    f_stale && build_module(string_to_flax(data, partial = partial), path)

    return Base.include(mod, joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl"))
  end

  getfield(mod, func_name)
end


"""
"""
function template(path::String; partial::Bool = true, mod::Module = @__MODULE__) :: String
  get_template(path, partial = partial, mod = mod) |> Base.invokelatest
end


"""
"""
function build_is_stale(file_path::String, build_path::String) :: Bool
  isfile(file_path) || return true

  file_mtime = stat(file_path).mtime
  build_mtime = stat(build_path).mtime
  status = file_mtime > build_mtime

  Genie.config.log_views && status && log("🚨  Flax view $file_path build $build_path is stale")

  status
end


"""
"""
function register_vars(vars...) :: Nothing
  init_task_local_storage()
  task_local_storage(:__vars, merge(Dict{Symbol,Any}(vars), task_local_storage(:__vars)))

  nothing
end


"""
"""
function html_renderer(resource::Union{Symbol,String}, action::Union{Symbol,String}; layout::Union{Symbol,String} = Genie.config.renderer_default_layout_file, mod::Module = @__MODULE__, vars...) :: Function
  register_vars(vars...)
  task_local_storage(:__yield, get_template(joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action)), partial = true, mod = mod) |> Base.invokelatest)

  layout = Base.get(task_local_storage(:__vars), :layout, layout)

  get_template(joinpath(Genie.APP_PATH, Genie.LAYOUTS_FOLDER, string(layout)), partial = false, mod = mod)
end
function html_renderer(data::String; mod::Module = @__MODULE__, layout::Union{Symbol,String,Nothing} = nothing, vars...) :: Function
  register_vars(vars...)

  if layout != nothing
    task_local_storage(:__yield, parse_view(data, partial = true, mod = mod))
    get_template(joinpath(Genie.APP_PATH, Genie.LAYOUTS_FOLDER, string(layout)), partial = false, mod = mod)
  else
    parse_view(data, partial = false, mod = mod)
  end
end


"""
"""
function json_renderer(resource::Union{Symbol,String}, action::Union{Symbol,String}; mod::Module = @__MODULE__, vars...) :: Function
  register_vars(vars...)

    () -> (Base.include(mod, joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action) * JSON_FILE_EXT)) |> JSON.json)
end


"""
    function_name(file_path::String)

Generates function name for generated Flax views.
"""
function function_name(file_path::String) :: String
  file_path = relpath(file_path)
  "func_$(sha1(file_path) |> bytes2hex)"
end


"""
    m_name(file_path::String)

Generates module name for generated Flax views.
"""
function m_name(file_path::String) :: String
  file_path = relpath(file_path)
  "$(sha1(file_path) |> bytes2hex)"
end


"""
    html_to_flax(file_path::String; partial = true) :: String

Converts a HTML document to a Flax document.
"""
function html_to_flax(file_path::String; partial = true) :: String
  to_flax(file_path, parse_template, partial = partial)
end


"""
"""
function string_to_flax(content::String; partial = true, f_name::Union{Symbol,Nothing} = nothing) :: String
  to_flax(content, parse_string, partial = partial, f_name = f_name)
end


"""
"""
function to_flax(input::String, f::Function; partial = true, f_name::Union{Symbol,Nothing} = nothing) :: String
  f_name = f_name === nothing ? function_name(input) : f_name

  string("function $(f_name)() \n",
          f(input, partial = partial),
          "\nend \n")
end


"""
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
"""
function build_inline_module(module_name::String, content::String) :: Bool
  module_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, module_name * ".jl")
  isdir(joinpath(Genie.BUILD_PATH, BUILD_NAME)) || mkpath(joinpath(Genie.BUILD_PATH, BUILD_NAME))
  open(module_path, "w") do io
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

Parses a HTML file into a `string` of Flax code.
"""
function parse_template(file_path::String; partial = true) :: String
  parse(read_template_file(file_path), partial = partial)
end


"""
"""
function parse_string(data::String; partial = true) :: String
  parse(parse_tags(data), partial = partial)
end


"""
"""
function parse(input::String; partial = true) :: String
  parse_tree(Gumbo.parsehtml(input).root, "", 0, partial = partial)
end


"""
    parse_tree(elem, output, depth; partial = true) :: String

Parses a Gumbo tree structure into a `string` of Flax code.
"""
function parse_tree(elem::Union{HTMLElement,HTMLText}, output::String = "", depth::Int = 0; partial = true) :: String
  io = IOBuffer()

  if isa(elem, HTMLElement)
    tag_name = replace(lowercase(string(tag(elem))), "-"=>"_")

    if Genie.config.flax_autoregister_webcomponents && ! isdefined(@__MODULE__, Symbol(tag_name))
      log("Autoregistering HTML element $tag_name", :debug)

      register_element(Symbol(tag_name))
      print(io, "Genie.Flax.register_element(Symbol(\"$tag_name\")) \n")
    end

    invalid_tag = partial && (tag_name == "html" || tag_name == "head" || tag_name == "body")

    if tag_name == "script" && in("type", collect(keys(attrs(elem))))
      if attrs(elem)["type"] == "julia/eval"
        if ! isempty(children(elem))
          print(io, repeat("\t", depth), string(children(elem)[1].text), "\n")
        end
      end

    else
      print(io, repeat("\t", depth), ( ! invalid_tag ? "Flax.$(tag_name)(" : "Flax.skip_element(" ))

      attributes = IOBuffer()
      for (k,v) in attrs(elem)
        x = v

        if startswith(v, "<\$") && endswith(v, "\$>")
          v = (replace(replace(replace(v, "<\$"=>""), "\$>"=>""), "'"=>"\"") |> strip)
          x = v
          v = "\$($v)"
        end

        if in(Symbol(lowercase(k)), BOOL_ATTRIBUTES)
          if x == true || x == "true" || x == :true || x == ":true" || x == ""
            # push!(attributes, "$k = \"$k\"") # boolean attributes can have the same value as the attribute -- or be empty
            print(attributes, "$k = \"$k\"", ", ") # boolean attributes can have the same value as the attribute -- or be empty
          end
        else
          print(attributes, """$(replace(lowercase(string(k)), "-"=>"_")) = "$v" """, ", ")
        end
      end

      attributes_string = String(take!(attributes))
      endswith(attributes_string, ", ") && (attributes_string = attributes_string[1:end-2])
      print(io, attributes_string, ") ")

      inner = ""
      if ! isempty(children(elem))
        children_count = size(children(elem))[1]

        print(io, "do;[\n")

        idx = 0
        for child in children(elem)
          idx += 1
          inner *= parse_tree(child, "", depth + 1, partial = partial)
          if idx < children_count
            if isa(child, HTMLText) ||
                ( isa(child, HTMLElement) && ( ! in("type", collect(keys(attrs(child)))) || ( in("type", collect(keys(attrs(child)))) && (attrs(child)["type"] != "julia/eval") ) ) )
                ! isempty(inner) && (inner = repeat("\t", depth) * inner * "\n")
            end
          end
        end
        isempty(inner) || (print(io, inner, "\n", repeat("\t", depth)))

        print(io, "]end\n")
      end
    end

  elseif isa(elem, HTMLText)
    content = replace(elem.text |> strip |> string, "\""=>"\\\"")
    print(io, repeat("\t", depth), "\"$(content)\"")
  end

  String(take!(io))
end


"""
    parse_tags(line::Tuple{Int64,String}, strip_close_tag = false) :: String

Parses special Flax tags.
"""
function parse_tags(line::Tuple{Int64,String}) :: String
  parse_tags(line[2])
end
function parse_tags(code::String) :: String
  code = replace(code, "<%"=>"""<script type="julia/eval">""")
  replace(code, "%>"=>"""</script>""")
end


"""
Outputs document's doctype.
"""
function doctype(doctype::Symbol = :html) :: HTMLString
  "<!DOCTYPE $doctype>"
end


"""
Outputs document's doctype.
"""
function doc(html::String) :: HTMLString
  doctype() * "\n" * html
end
function doc(doctype::Symbol, html::String) :: HTMLString
  doctype(doctype) * "\n" * html
end


"""
    register_elements() :: Nothing

Generated functions that represent Flax functions definitions corresponding to HTML elements.
"""
function register_elements() :: Nothing
  for elem in NORMAL_ELEMENTS
    register_normal_element(elem)
  end

  for elem in VOID_ELEMENTS
    register_void_element(elem)
  end

  nothing
end


function register_element(elem::Symbol, elem_type::Symbol = :normal) :: Nothing
  elem_type == :normal ? register_normal_element(elem) : register_void_element(elem)
end


"""
"""
function register_normal_element(elem::Symbol) :: Nothing
  Core.eval(@__MODULE__, """
    function $elem(f::Function; attrs...) :: HTMLString
      \"\"\"\$(normal_element(f, "$(string(elem))", Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)
  Core.eval(@__MODULE__, """
    function $elem(children::Union{String,Vector{String}} = ""; attrs...) :: HTMLString
      \"\"\"\$(normal_element(children, "$(string(elem))", Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  nothing
end


"""
"""
function register_void_element(elem::Symbol) :: Nothing
  Core.eval(@__MODULE__, """
    function $elem(; attrs...) :: HTMLString
      \"\"\"\$(void_element("$(string(elem))", Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  nothing
end

push!(LOAD_PATH,  abspath(Genie.HELPERS_PATH))


"""
"""
macro foreach(f, arr)
  quote
    isempty($(esc(arr))) && return ""
    mapreduce(*, $(esc(arr))) do _s
      $f(_s) * "\n"
    end
  end
end


function foreachstr(f, arr)
  isempty(arr) && return ""
  mapreduce(*, arr) do _s
    f(_s)
  end
end


"""
    foreachvar(f::Function, key::Symbol, v::Vector) :: String

Utility function for looping over a `vector` `v` in the view layer.
"""
function foreachvar(f::Function, key::Symbol, v::Vector) :: String
  isempty(v) && return ""

  output = mapreduce(*, v) do (value)
    vars = task_local_storage(:__vars)
    vars[key] = value
    task_local_storage(:__vars, vars)

    f(value)
  end

  vars = task_local_storage(:__vars)
  delete!(vars, key)
  task_local_storage(:__vars, vars)

  output
end

register_elements()


"""
    var_dump(var, html = true) :: String

Utility function for dumping a variable.
"""
function var_dump(var, html = true) :: String
  iobuffer = IOBuffer()
  show(iobuffer, var)
  content = String(take!(iobuffer))

  html ? replace(replace("<code>$content</code>", "\n"=>"<br>"), " "=>"&nbsp;") : content
end


"""
"""
macro vars()
  :(task_local_storage(:__vars))
end
macro vars(key)
  :(task_local_storage(:__vars)[$key])
end
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
  OrderedDict(vars)
end


"""
    prepare_build() :: Bool

Sets up the build folder and the build module file for generating the compiled views.
"""
function prepare_build(subfolder) :: Bool
  build_path = joinpath(Genie.BUILD_PATH, subfolder)
  @ifdev rm(build_path, force = true, recursive = true)
  if ! isdir(build_path)
    log("Creating build folder at $(build_path)", :info)
    mkpath(build_path)
  end

  true
end


"""
"""
function create_build_folders()
  prepare_build(BUILD_NAME)
end

end