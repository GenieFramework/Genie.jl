"""
Compiled templating language for Genie.
"""
module Flax

using Revise, Gumbo, SHA, Reexport, JSON, OrderedCollections, Markdown
using Genie, Genie.Loggers, Genie.Configuration
@reexport using HttpCommon

export HTMLString, JSONString, JSString, SyncBinding, DataSyncBinding, ComputedSyncBinding, MethodSyncBinding
export doctype, var_dump, include_template, @vars, @yield, el, foreachvar, @foreach, foreachstr, binding, syncid

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

const FILE_EXT      = ".flax.jl"
const TEMPLATE_EXT  = [".flax.html", ".jl.html"]
const JSON_FILE_EXT = ".json.jl"
const MARKDOWN_FILE_EXT = [".md", ".jl.md"]

const SUPPORTED_HTML_OUTPUT_FILE_FORMATS = [TEMPLATE_EXT...]

const HTMLString = String
const JSONString = String

const BUILD_NAME    = "FlaxViews"
const MD_BUILD_NAME = "MarkdownViews"


task_local_storage(:__vars, Dict{Symbol,Any}())
task_local_storage(:__yield, "")


function extract(data)
  if isa(data, Function)
    data()
  elseif isa(data, Signal)
    value(data)
  else
    data
  end
end


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
    include_template(path::String; partial = true) :: String

Includes a template inside another.
"""
function include_template(path::String; partial = true) :: String
  if Genie.config.log_views
    log("Including $path")
    @time _include_template(path, partial = partial)
  else
    _include_template(path, partial = partial)
  end
end


"""
"""
function view_file_info(path::String) :: Tuple{String,String}
  _path, _extension = "", ""

  if isfile(abspath(path))
    _path, _extension = relpath(path), "." * split(path, ".")[end]
  else
    for file_extension in SUPPORTED_HTML_OUTPUT_FILE_FORMATS
      if isfile(abspath(path * file_extension))
        _path, _extension = abspath(path * file_extension), file_extension
        break
      end
    end
  end

  _path, _extension
end


"""
"""
function include_markdown(path::String)
  Markdown.parse(include_string(@__MODULE__, string('"', read(path, String), '"'))) |> Markdown.html
end


"""
"""
function render_markdown(content::Markdown.MD)
  content |> Markdown.html
end


"""
"""
function _include_template(path::String; partial = true) :: String
  _path, _extension = view_file_info(path)

  isempty(_path) ? error("File not found $(abspath(path)) in $(@__FILE__):$(@__LINE__)") : path = _path

  _extension in MARKDOWN_FILE_EXT && return include_markdown(path)

  f_name = Symbol(function_name(path))
  f_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl")
  f_stale = build_is_stale(path, f_path)

  if f_stale || ! isdefined(@__MODULE__, f_name)
    if f_stale
      log("Building view $path")
      @time build_module(html_to_flax(path, partial = partial), path)
    end
    include(joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl"))
  end

  try
    Base.invokelatest(getfield(@__MODULE__, f_name))
  catch ex
    log("$ex at $(@__FILE__):$(@__LINE__)", :err)
  end
end


"""
"""
function _include_inline_template(content::Union{HTMLString,Markdown.MD}; partial = true) :: String
  isa(content, Markdown.MD) && return render_markdown(content)

  module_name = m_name(content)

  f_name = Symbol(function_name(content))
  f_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, module_name * ".jl")
  f_stale = ! isfile(f_path)

  if f_stale || ! isdefined(@__MODULE__, f_name)
    if f_stale
      log("Building view $f_path")
      @time build_inline_module(module_name, string_to_flax(content, partial = partial))
    end
    include(joinpath(Genie.BUILD_PATH, BUILD_NAME, module_name * ".jl"))
  end

  try
    Base.invokelatest(getfield(@__MODULE__, f_name))
  catch ex
    log("$ex at $(@__FILE__):$(@__LINE__)", :err)
  end
end


"""
"""
function md_build_name(path::String) :: String
  replace(path, "/"=>"_") # * ".jl.html"
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
    render_html(resource::Symbol, action::Symbol, layout::Symbol; vars...) :: Dict{Symbol,String}

Renders a HTML view corresponding to a resource and a controller action.
"""
function render_html(resource::Symbol, action::Symbol, layout::Symbol; vars...) :: Dict{Symbol,String}
  try
    task_local_storage(:__vars, Dict{Symbol,Any}(vars))
    task_local_storage(:__yield, include_template(joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action))))

    Dict{Symbol,String}(:html => include_template(joinpath(Genie.APP_PATH, Genie.LAYOUTS_FOLDER, string(layout)), partial = false) |> string |> doc)
  catch ex
    log(string(ex))
    log("$(@__FILE__):$(@__LINE__)")

    rethrow(ex)
  end
end
function render_html(view::String, layout::String = "<% @yield %>"; vars...) :: Dict{Symbol,String}
  try
    task_local_storage(:__vars, Dict{Symbol,Any}(vars))

    if ispath(view)
      task_local_storage(:__yield, include_template(view))
    else
      task_local_storage(:__yield, _include_inline_template(view))
      # task_local_storage(:__yield, Core.eval(@__MODULE__, Meta.parse(parse_string(view))))
    end

    if ispath(layout)
      Dict{Symbol,String}(:html => include_template(layout, partial = false) |> string |> doc)
    else
      Dict{Symbol,String}(:html => _include_inline_template(layout, partial = false) |> string |> doc)
      # Dict{Symbol,String}(:html => Core.eval(@__MODULE__, Meta.parse(parse_string(layout, partial = false))) |> string |> doc)
    end
  catch ex
    log(string(ex), :err)
    log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end
end


"""
    render_flax(resource::Symbol, action::Symbol, layout::Symbol; vars...) :: Dict{Symbol,String}

Renders a Flax view corresponding to a resource and a controller action.
"""
function render_flax(resource::Union{Symbol,String}, action::Union{Symbol,String}, layout::Union{Symbol,String}; vars...) :: Dict{Symbol,String}
  err_msg = "The Flax view must return a function"

  try
    julia_action_template_func = joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action) * FILE_EXT) |> include
    julia_layout_template_func = joinpath(Genie.APP_PATH, Genie.LAYOUTS_FOLDER, string(layout) * FILE_EXT) |> include

    task_local_storage(:__vars, Dict{Symbol,Any}(vars))

    if isa(julia_action_template_func, Function)
      task_local_storage(:__yield, julia_action_template_func())
    else
      log(err_msg, :err)
      log("$(@__FILE__):$(@__LINE__)")

      throw(err_msg)
    end

    return  if isa(julia_layout_template_func, Function)
              Dict{Symbol,String}(:html => julia_layout_template_func() |> string |> doc)
            else
              log(err_msg, :err)
              log("$(@__FILE__):$(@__LINE__)")

              throw(err_msg)
            end
  catch ex
    log(string(ex), :err)
    log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end
end


"""
    json(resource::Symbol, action::Symbol; vars...) :: Dict{Symbol,String}

Renders a JSON view corresponding to a resource and a controller action.
"""
function render_json(resource::Union{Symbol,String}, action::Union{Symbol,String}; vars...) :: Dict{Symbol,String}
  try
    task_local_storage(:__vars, Dict{Symbol,Any}(vars))

    return Dict{Symbol,String}(:json => (joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action) * JSON_FILE_EXT) |> include) |> JSON.json)
  catch ex
    log("Error generating JSON view", :err)
    log(string(ex), :err)
    log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end
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
  string("function $(function_name(file_path))() \n",
          parse_template(file_path, partial = partial),
          "\nend \n")
end


function string_to_flax(content::String; partial = true) :: String
  string("function $(function_name(content))() \n",
          parse_string(content, partial = partial),
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
  htmldoc = read_template_file(file_path) |> Gumbo.parsehtml
  parse_tree(htmldoc.root, "", 0, partial = partial)
end


"""
"""
function parse_string(s::String; partial = true) :: String
  htmldoc = parse_tags(s) |> Gumbo.parsehtml
  parse_tree(htmldoc.root, "", 0, partial = partial)
end


"""
    parse_tree(elem, output, depth; partial = true) :: String

Parses a Gumbo tree structure into a `string` of Flax code.
"""
function parse_tree(elem::Union{HTMLElement,HTMLText}, output::String = "", depth::Int = 0; partial = true) :: String
  io = IOBuffer()

  if isa(elem, HTMLElement)

    tag_name = replace(lowercase(string(tag(elem))), "-"=>"_")
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
    print(io, repeat("\t", depth), "\"$(elem.text |> strip |> string)\"")
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
    doctype(doctype::Symbol = :html) :: String

Outputs document's doctype.
"""
function doctype(doctype::Symbol = :html) :: String
  "<!DOCTYPE $doctype>"
end


"""
    doc(html::String) :: String
    doc(doctype::Symbol, html::String) :: String

Outputs document's doctype.
"""
function doc(html::String) :: String
  doctype() * "\n" * html
end
function doc(doctype::Symbol, html::String) :: String
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


function register_element(elem::Symbol, elem_type::Symbol = :normal)
  elem_type != :normal && elem_type != :void && error("elem_type must be one of :normal or :void")

  elem_type == :normal ? register_normal_element(elem) : register_void_element(elem)
end


"""
"""
function register_normal_element(elem::Symbol)
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
end


"""
"""
function register_void_element(elem::Symbol)
  Core.eval(@__MODULE__, """
    function $elem(; attrs...) :: HTMLString
      \"\"\"\$(void_element("$(string(elem))", Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)
end

push!(LOAD_PATH,  abspath(Genie.HELPERS_PATH))


"""
"""
macro foreach(f, arr)
  quote
    isempty($arr) && return ""
    mapreduce(*, $arr) do _s
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

macro vars()
  :(task_local_storage(:__vars))
end
macro vars(key)
  :(task_local_storage(:__vars)[$key])
end
macro vars(key, value)
  :(task_local_storage(:__vars)[$key] = $value)
end
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
  isdir(build_path) || mkpath(build_path)

  true
end


"""
"""
function create_build_folders()
  prepare_build(BUILD_NAME)
  prepare_build(MD_BUILD_NAME)
end


Genie.config.flax_compile_templates && create_build_folders()

end
