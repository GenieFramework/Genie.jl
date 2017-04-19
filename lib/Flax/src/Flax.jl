module Flax

using Genie, Renderer, Gumbo, Logger, Configuration, Router, SHA, App, Reexport, JSON, DataStructures
using ControllerHelper, ValidationHelper
@dependencies

export HTMLString, JSONString
export doctype, var_dump, include_template, @vars, @yield, el, foreachvar

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
                          :slot, :template, :blockquote]
const VOID_ELEMENTS   = [:base, :link, :meta, :hr, :br, :area, :img, :track, :param, :source, :input]
const BOOL_ATTRIBUTES = [:checked, :disabled, :selected]

const FILE_EXT      = ".flax.jl"
const TEMPLATE_EXT  = ".flax.html"
const JSON_FILE_EXT = ".json.jl"

typealias HTMLString String
typealias JSONString String

task_local_storage(:__vars, Dict{Symbol,Any}())

function prepare_template(s::String)
  s
end
function prepare_template{T}(v::Vector{T})
  filter!(v) do (x)
    ! isa(x, Void)
  end
  join(v)
end

function attributes(attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: Vector{String}
  a = String[]
  for (k,v) in attrs
    if startswith(v, "<:") && endswith(v, ":>")
      v = (replace(replace(replace(v, "<:", ""), ":>", ""), "'", "\"") |> strip)
      v = "\$($v)"
    end
    push!(a, """$(k)=\"$(v)\" """)
  end

  a
end

function normal_element(f::Function, elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString
  a = attributes(attrs)

  """<$( string(lowercase(elem)) * (! isempty(a) ? (" " * join(a, " ")) : "") )>\n$(prepare_template(f()))\n</$( string(lowercase(elem)) )>\n"""
end
function normal_element(elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString
  a = attributes(attrs)

  """<$( string(lowercase(elem)) * (! isempty(a) ? (" " * join(a, " ")) : "") )></$( string(lowercase(elem)) )>\n"""
end

function void_element(elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString
  a = attributes(attrs)

  "<$( string(lowercase(elem)) * (! isempty(a) ? (" " * join(a, " ")) : "") )>\n"
end

function skip_element(f::Function) :: HTMLString
  """$(prepare_template(f()))\n"""
end
function skip_element() :: HTMLString
  ""
end

function include_template(path::String; partial = true, func_name = "") :: String
  if App.config.log_views
    Logger.log("Including $path", :info)
    @time _include_template(path, partial = partial, func_name = func_name)
  else
    _include_template(path, partial = partial, func_name = func_name)
  end
end
function _include_template(path::String; partial = true, func_name = "") :: String
  path = relpath(path)

  f_name = func_name != "" ? Symbol(func_name) : Symbol(function_name(path))
  Genie.config.flax_compile_templates && isdefined(f_name) && return getfield(current_module(), f_name)()

  if Genie.config.flax_compile_templates
    file_path = joinpath(Genie.config.cache_folder, path) * FILE_EXT
    cache_file_name = sha1(path)

    if isfile(file_path)
      App.config.log_views && Logger.log("Hit cache for view $path", :info)
      return (file_path |> include)()
    else
      flax_code = html_to_flax(path, partial = partial)
      if ! isdir(joinpath(Genie.config.cache_folder, dirname(path)))
        mkpath(joinpath(Genie.config.cache_folder, dirname(path)))
      end
      open(file_path, "w") do io
        write(io, flax_code)
      end
      return (flax_code |> include_string)()
    end
  end

  flax_code = html_to_flax(path, partial = partial)
  try
    (flax_code |> include_string)()
  catch ex
    @show flax_code
    rethrow(ex)
  end
end

function html(resource::Symbol, action::Symbol, layout::Symbol; vars...) :: Dict{Symbol,String}
  try
    task_local_storage(:__vars, Dict{Symbol,Any}(vars))
    task_local_storage(:__yield, include_template(joinpath(Genie.RESOURCE_PATH, string(resource), Renderer.VIEWS_FOLDER, string(action) * TEMPLATE_EXT)))

    Dict{Symbol,AbstractString}(:html => include_template(joinpath(Genie.APP_PATH, Renderer.LAYOUTS_FOLDER, string(layout) * TEMPLATE_EXT), partial = false) |> string |> doc)
  catch ex
    if Configuration.is_dev()
      rethrow(ex)
    else
      Router.serve_error_file_500()
    end
  end
end

function flax(resource::Symbol, action::Symbol, layout::Symbol; vars...) :: Dict{Symbol,String}
  try
    julia_action_template_func = joinpath(Genie.RESOURCE_PATH, string(resource), Renderer.VIEWS_FOLDER, string(action) * FILE_EXT) |> include
    julia_layout_template_func = joinpath(Genie.APP_PATH, Renderer.LAYOUTS_FOLDER, string(layout) * FILE_EXT) |> include

    task_local_storage(:__vars, Dict{Symbol,Any}(vars))

    if isa(julia_action_template_func, Function)
      task_local_storage(:__yield, julia_action_template_func())
    else
      message = "The Flax view should return a function"
      Logger.log(message, :err)
      Logger.@location

      throw(message)
    end

    return  if isa(julia_layout_template_func, Function)
              Dict{Symbol,AbstractString}(:html => julia_layout_template_func() |> string |> doc)
            else
              message = "The Flax template should return a function"
              Logger.log(message, :err)
              Logger.@location

              throw(message)
            end
  catch ex
    if Configuration.is_dev()
      rethrow(ex)
    else
      Router.serve_error_file_500()
    end
  end
end

function json(resource::Symbol, action::Symbol; vars...) :: Dict{Symbol,String}
  try
    task_local_storage(:__vars, Dict{Symbol,Any}(vars))

    return Dict{Symbol,AbstractString}(:json => (joinpath(Genie.RESOURCE_PATH, string(resource), Renderer.VIEWS_FOLDER, string(action) * JSON_FILE_EXT) |> include) |> JSON.json)
  catch ex
    if Configuration.is_dev()
      rethrow(ex)
    else
      Router.serve_error_file_500()
    end
  end
end

function function_name(file_path::String)
  file_path = relpath(file_path)
  "func_$(sha1(file_path) |> bytes2hex )"
end

function html_to_flax(file_path::String; partial = true) :: String
  code =  """using Flax\n"""
  code *= """function $(function_name(file_path))() \n"""
  code *= parse_template(file_path, partial = partial)
  code *= """\nend"""

  code
end

function read_template_file(file_path::String) :: String
  html = String[]
  open(file_path) do f
    for line in enumerate(eachline(f))
      push!(html, parse_tags(line))
    end
  end

  join(html, "\n")
end

function parse_template(file_path::String; partial = true) :: String
  htmldoc = read_template_file(file_path) |> Gumbo.parsehtml
  parse_tree(htmldoc.root, "", 0, partial = partial)
end

function parse_tree(elem, output, depth; partial = true) :: String
  if isa(elem, HTMLElement)

    tag_name = lowercase(string(tag(elem)))
    invalid_tag = partial && (tag_name == "html" || tag_name == "head" || tag_name == "body")

    if tag_name == "script" && in("type", collect(keys(attrs(elem))))

      if attrs(elem)["type"] == "julia/eval"
        if ! isempty(children(elem))
          output *= repeat("\t", depth) * string(children(elem)[1].text) * " \n"
        end
      end

    else

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

      output *= join(attributes, ", ") * ") "
      # end

      inner = ""
      if ! isempty(children(elem))
        children_count = size(children(elem))[1]

        output *= " do;[ \n"

        idx = 0
        for child in children(elem)
          idx += 1
          inner *= parse_tree(child, "", depth + 1, partial = partial)
          if idx < children_count
            if isa(child, HTMLText) ||
                ( isa(child, HTMLElement) && ( ! in("type", collect(keys(attrs(child)))) || ( in("type", collect(keys(attrs(child)))) && (attrs(child)["type"] != "julia/eval") ) ) )
                ! isempty(inner) && (inner = repeat("\t", depth) * inner * " \n")
            end
          end
        end
        ! isempty(inner) && (output *= inner * "\n " * repeat("\t", depth))

        output *= "]end \n"
      end
    end

  elseif isa(elem, HTMLText)
    content = replace(elem.text, r"<:(.*):>", (x) -> replace(replace(x, "<:", ""), ":>", "") |> strip |> string )
    output *= repeat("\t", depth) * "\"$(content)\""
  end

  # @show output
  output
end

function parse_tags(line::Tuple{Int64,String}, strip_close_tag = false) :: String
  code = line[2]

  code = replace(code, "<%", """<script type="julia/eval">""")
  code = replace(code, "%>", strip_close_tag ? "" : """</script>""")

  code
end

function doctype(doctype::Symbol = :html) :: String
  "<!DOCTYPE $doctype>"
end
function doc(html::String) :: String
  doctype() * "\n" * html
end
function doc(doctype::Symbol, html::String) :: String
  doctype(doctype) * "\n" * html
end

function register_elements()
  for elem in NORMAL_ELEMENTS
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

    # @eval export $elem
  end

  for elem in VOID_ELEMENTS
    """
      function $elem(attrs::Pair{Symbol,String}...) :: HTMLString
        \"\"\"\$(void_element("$(string(elem))", Pair{Symbol,String}[attrs...]))\"\"\"
      end
    """ |> parse |> eval

    # @eval export $elem
  end
end

push!(LOAD_PATH,  abspath(Genie.HELPERS_PATH))

function include_helpers()
  for h in readdir(Genie.HELPERS_PATH)
    if isfile(joinpath(Genie.HELPERS_PATH, h)) && endswith(h, "Helper.jl")
      eval("""@reexport using $(replace(h, r"\.jl$", ""))""" |> parse)
    end
  end
end

function foreachvar(f::Function, key::Symbol, v::Vector)
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
include_helpers()

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

end
