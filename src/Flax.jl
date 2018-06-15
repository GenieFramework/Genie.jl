"""
Compiled templating language for Genie.
"""
module Flax

using Revise, Genie, Gumbo, Genie.Logger, Genie.Configuration, SHA, Reexport, JSON, DataStructures, Revise
@reexport using HttpCommon

export HTMLString, JSONString
export doctype, var_dump, include_template, @vars, @yield, el, foreachvar, @foreach

import Base.string

const NORMAL_ELEMENTS = [ :html, :head, :body, :title, :style, :address, :article, :aside, :footer,
                          :header, :h1, :h2, :h3, :h4, :h5, :h6, :hgroup, :nav, :section,
                          :dd, :div, :dl, :dt, :figcaption, :figure, :li, :main, :ol, :p, :pre, :ul, :span,
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
const TEMPLATE_EXT  = ".flax.html"
const JSON_FILE_EXT = ".json.jl"
const MARKDOWN_FILE_EXT = ".md"

const SUPPORTED_HTML_OUTPUT_FILE_FORMATS = [TEMPLATE_EXT, MARKDOWN_FILE_EXT]

const HTMLString = String
const JSONString = String

const BUILD_NAME    = "FlaxViews"
const MD_BUILD_NAME = "MarkdownViews"


task_local_storage(:__vars, Dict{Symbol,Any}())


"""
    prepare_template(s::String)
    prepare_template{T}(v::Vector{T})

Cleans up the template before rendering (ex by removing empty nodes).
"""
function prepare_template(s::String) :: String
  s
end
function prepare_template{T}(v::Vector{T}) :: String
  filter!(v) do (x)
    ! isa(x, Void)
  end
  join(v)
end


"""
    attributes(attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: Vector{String}

Parses HTML attributes.
"""
function attributes(attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: Vector{String}
  a = String[]
  for (k,v) in attrs
    push!(a, "$(k)=\"$(v)\"")
  end

  a
end


function normalize_element(elem::String)
  replace(string(lowercase(elem)), "_", "-")
end


"""
    normal_element(f::Function, elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString

Generates a regular HTML element in the form <...></...>
"""
function normal_element(f::Function, elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString
  a = attributes(attrs)
  elem = normalize_element(elem)

  "<$(elem * (! isempty(a) ? (" " * join(a, " ")) : ""))>$(prepare_template(f()))</$(elem)>"
end
function normal_element(elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString
  a = attributes(attrs)
  elem = normalize_element(elem)

  "<$(elem * (! isempty(a) ? (" " * join(a, " ")) : ""))></$(elem)>"
end


"""
    void_element(elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString

Generates a void HTML element in the form <...>
"""
function void_element(elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString
  a = attributes(attrs)
  elem = normalize_element(elem)

  "<$(elem * (! isempty(a) ? (" " * join(a, " ")) : ""))>"
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
    include_template(path::String; partial = true, func_name = "") :: String

Includes a template inside another.
"""
function include_template(path::String; partial = true, func_name = "") :: String
  if Genie.config.log_views
    Logger.log("Including $path", :info)
    @time _include_template(path, partial = partial, func_name = func_name)
  else
    _include_template(path, partial = partial, func_name = func_name)
  end
end
function _include_template(path::String; partial = true, func_name = "") :: String
  _path, _extension = "", ""
  if isfile(abspath(path))
    _path, _extension = relpath(path), "." * split(path, ".")[end]
  else
    for file_extension in SUPPORTED_HTML_OUTPUT_FILE_FORMATS
      if isfile(relpath(path * file_extension))
        _path, _extension = relpath(path * file_extension), file_extension
        break
      end
    end
  end

  _path == "" ? error("File not found $path in $(@__FILE__):$(@__LINE__)") : path = _path

  if _extension == MARKDOWN_FILE_EXT # .md
    build_path = joinpath(Genie.BUILD_PATH, MD_BUILD_NAME, md_build_name(path))
    isfile(build_path) && ! build_is_stale(path, build_path) && return readstring(build_path)

    md_html = Markdown.parse(include_string(string('"', readstring(path), '"'))) |> Markdown.html
    open(joinpath(Genie.BUILD_PATH, MD_BUILD_NAME, md_build_name(path)), "w") do io
      write(io, md_html)
    end

    return md_html
  end

  f_name = func_name != "" ? Symbol(func_name) : Symbol(function_name(path))
  try
    build_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl")

    stale_build = build_is_stale(path, build_path)

    isdefined(Genie.Renderer.Flax, f_name) && ! stale_build && return getfield(Genie.Renderer.Flax, f_name)()

    if ! stale_build
      include(joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl"))
      return eval("$(f_name)()" |> parse)
    end

    build_module(html_to_flax(path, partial = partial), path)
    f = include(joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl"))
    return eval("$(f_name)()" |> parse)

  catch ex
    Genie.Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end
end


"""
"""
function md_build_name(path::String) :: String
  replace(path, "/", "_")
end


"""
"""
function build_is_stale(file_path::String, build_path::String) :: Bool
  isfile(file_path) || return true

  file_mtime = stat(file_path).mtime
  build_mtime = stat(build_path).mtime
  status = file_mtime > build_mtime

  Genie.config.log_views && status && Logger.log("🚨  Flax view $file_path build $build_path is stale")

  status
end


"""
    html(resource::Symbol, action::Symbol, layout::Symbol; vars...) :: Dict{Symbol,String}

Renders a HTML view corresponding to a resource and a controller action.
"""
function html(resource::Union{Symbol,String}, action::Union{Symbol,String}, layout::Union{Symbol,String}; vars...) :: Dict{Symbol,String}
  try
    task_local_storage(:__vars, Dict{Symbol,Any}(vars))
    task_local_storage(:__yield, include_template(joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action))))

    Dict{Symbol,AbstractString}(:html => include_template(joinpath(Genie.APP_PATH, Genie.LAYOUTS_FOLDER, string(layout)), partial = false) |> string |> doc)
  catch ex
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end
end
function html(view::String, layout::String = "<% @yield %>"; vars...) :: Dict{Symbol,String}
  try
    task_local_storage(:__vars, Dict{Symbol,Any}(vars))
    task_local_storage(:__yield, eval(parse(parse_string(view))))

    Dict{Symbol,AbstractString}(:html => eval(parse(parse_string(layout, partial = false))) |> string |> doc)
  catch ex
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end
end


"""
    flax(resource::Symbol, action::Symbol, layout::Symbol; vars...) :: Dict{Symbol,String}

Renders a Flax view corresponding to a resource and a controller action.
"""
function flax(resource::Union{Symbol,String}, action::Union{Symbol,String}, layout::Union{Symbol,String}; vars...) :: Dict{Symbol,String}
  err_msg = "The Flax view must return a function"
  try
    julia_action_template_func = joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action) * FILE_EXT) |> include
    julia_layout_template_func = joinpath(Genie.APP_PATH, Genie.LAYOUTS_FOLDER, string(layout) * FILE_EXT) |> include

    task_local_storage(:__vars, Dict{Symbol,Any}(vars))

    if isa(julia_action_template_func, Function)
      task_local_storage(:__yield, julia_action_template_func())
    else
      Logger.log(err_msg, :err)
      Logger.log("$(@__FILE__):$(@__LINE__)")

      throw(err_msg)
    end

    return  if isa(julia_layout_template_func, Function)
              Dict{Symbol,AbstractString}(:html => julia_layout_template_func() |> string |> doc)
            else
              Logger.log(err_msg, :err)
              Logger.log("$(@__FILE__):$(@__LINE__)")

              throw(err_msg)
            end
  catch ex
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

    rethrow(ex)
  end
end


"""
    json(resource::Symbol, action::Symbol; vars...) :: Dict{Symbol,String}

Renders a JSON view corresponding to a resource and a controller action.
"""
function json(resource::Union{Symbol,String}, action::Union{Symbol,String}; vars...) :: Dict{Symbol,String}
  try
    task_local_storage(:__vars, Dict{Symbol,Any}(vars))

    return Dict{Symbol,AbstractString}(:json => (joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action) * JSON_FILE_EXT) |> include) |> JSON.json)
  catch ex
    Logger.log("Error generating JSON view", :err)
    Logger.log(string(ex), :err)
    Logger.log("$(@__FILE__):$(@__LINE__)", :err)

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
  code = ""
  # code =  """module $(m_name(file_path)) \n"""
  # code *= """using Genie, Genie.Flax, Genie.Router\n"""
  # code *= """export $(function_name(file_path)) \n"""
  code *= """function $(function_name(file_path))() \n"""
  code *= parse_template(file_path, partial = partial)
  code *= """\nend \n"""
  # code *= """\nend"""

  code
end


"""
"""
function build_module(content::String, path::String) :: Bool
  module_path = joinpath(Genie.BUILD_PATH, BUILD_NAME, m_name(path) * ".jl")
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
  html = String[]
  open(file_path) do f
    for line in enumerate(eachline(f))
      push!(html, parse_tags(line))
    end
  end

  join(html, "\n")
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
  if isa(elem, HTMLElement)

    tag_name = replace(lowercase(string(tag(elem))), "-", "_")
    invalid_tag = partial && (tag_name == "html" || tag_name == "head" || tag_name == "body")

    if tag_name == "script" && in("type", collect(keys(attrs(elem))))
      if attrs(elem)["type"] == "julia/eval"
        if ! isempty(children(elem))
          output *= repeat("\t", depth) * string(children(elem)[1].text) * "\n"
        end
      end

    else
      # output *= (repeat("\t", depth) * (invalid_tag ? "" : "Flax.$(tag_name)("))
      output *= repeat("\t", depth) * ( ! invalid_tag ? "Flax.$(tag_name)(" : "Flax.skip_element(" )

      attributes = String[]
      for (k,v) in attrs(elem)
        x = v

        if startswith(v, "<\$") && endswith(v, "\$>")
          v = (replace(replace(replace(v, "<\$", ""), "\$>", ""), "'", "\"") |> strip)
          x = v
          v = "\$($v)"
        end

        if in(Symbol(lowercase(k)), BOOL_ATTRIBUTES)
          if x == true || x == "true" || x == :true || x == ":true" || x == ""
            push!(attributes, ":$(Symbol(k)) => \"$k\"") # boolean attributes can have the same value as the attribute -- or be empty
          end
        else
          push!(attributes, """Symbol("$k") => "$v" """)
        end
      end

      # output *= invalid_tag ? "" : join(attributes, ", ") * ") "
      output *= join(attributes, ", ") * ") "

      inner = ""
      if ! isempty(children(elem))
        children_count = size(children(elem))[1]

        # output *= invalid_tag ? "" : "do;[\n"
        output *= "do;[\n"

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
        isempty(inner) || (output *= inner * "\n" * repeat("\t", depth))

        # output *= invalid_tag ? "" : "]end\n"
        output *= "]end\n"
      end
    end

  elseif isa(elem, HTMLText)
    # content = replace(elem.text, r"<:(.*):>", (x) -> replace(replace(x, "<:", ""), ":>", "") |> strip |> string)
    output *= repeat("\t", depth) * "\"$(elem.text |> strip |> string)\""
  end

  output
end


"""
    parse_tags(line::Tuple{Int64,String}, strip_close_tag = false) :: String

Parses special Flax tags.
"""
function parse_tags(line::Tuple{Int64,String}) :: String
  parse_tags(line[2])
end
function parse_tags(code::String) :: String
  # code = replace(code, "<%", """<script type="julia/eval">""")
  code = replace(code, "<%", "\$(")
  # replace(code, "%>", strip_close_tag ? "" : """</script>""")
  replace(code, "%>", ")")
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
    register_elements() :: Void

Generated functions that represent Flax functions definitions corresponding to HTML elements.
"""
function register_elements() :: Void
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
  """
    function $elem(f::Function = ()->"", attrs::Pair{Symbol,String}...) :: HTMLString
      \"\"\"\$(normal_element(f, "$(string(elem))", Pair{Symbol,String}[attrs...]))\"\"\"
    end
  """ |> parse |> eval

  """
    function $elem(attrs::Pair{Symbol,String}...) :: HTMLString
      \"\"\"\$(normal_element("$(string(elem))", Pair{Symbol,String}[attrs...]))\"\"\"
    end
  """ |> parse |> eval
end


"""
"""
function register_void_element(elem::Symbol)
  """
    function $elem(attrs::Pair{Symbol,String}...) :: HTMLString
      \"\"\"\$(void_element("$(string(elem))", Pair{Symbol,String}[attrs...]))\"\"\"
    end
  """ |> parse |> eval
end

push!(LOAD_PATH,  abspath(Genie.HELPERS_PATH))


"""
"""
macro foreach(f, arr)
  quote
    isempty($arr) && return ""
    mapreduce(*, $arr) do _s
      $f(_s)
    end
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
  content = takebuf_string(iobuffer)

  html ? replace(replace("<code>$content</code>", "\n", "<br>"), " ", "&nbsp;") : content
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
  :(task_local_storage(:__yield))
end

function el(; vars...)
  OrderedDict(vars)
end


"""
    prepare_build() :: Bool

Sets up the build folder and the build module file for generating the compiled views.
"""
function prepare_build(subfolder) :: Bool
  rm(subfolder, force = true, recursive = true)

  build_path = joinpath(Genie.BUILD_PATH, subfolder)
  isdir(build_path) || mkpath(build_path)
  push!(LOAD_PATH, build_path)

  true
end
prepare_build(BUILD_NAME)
prepare_build(MD_BUILD_NAME)

end
