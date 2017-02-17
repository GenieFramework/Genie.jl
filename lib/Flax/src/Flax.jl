module Flax

using Genie, Renderer, Gumbo, Logger, Configuration, Router, SHA, App, Reexport
using ControllerHelper, ValidationHelper
@dependencies

export HTMLString, doctype, d, var_dump, include_template, @vars, @yield

const NORMAL_ELEMENTS = [ :html, :head, :body, :title, :style, :address, :article, :aside, :footer,
                          :header, :h1, :h2, :h3, :h4, :h5, :h6, :hgroup, :nav, :section,
                          :dd, :div, :dl, :dt, :figcaption, :figure, :li, :main, :ol, :p, :pre, :ul, :span,
                          :a, :abbr, :b, :bdi, :bdo, :cite, :code, :data, :dfn, :em, :i, :kbd, :mark,
                          :q, :rp, :rt, :rtc, :ruby, :s, :samp, :small, :spam, :strong, :sub, :sup, :time,
                          :u, :var, :wrb, :audio, :map, :void, :embed, :object, :canvas, :noscript, :script,
                          :del, :ins, :caption, :col, :colgroup, :table, :tbody, :td, :tfoot, :th, :thead, :tr,
                          :button, :datalist, :fieldset, :form, :label, :legend, :meter, :optgroup, :option,
                          :output, :progress, :select, :textarea, :details, :dialog, :menu, :menuitem, :summary,
                          :slot, :template]
const VOID_ELEMENTS   = [:base, :link, :meta, :hr, :br, :area, :img, :track, :param, :source, :input,
                          :html, :head, :body, :title, :style, :address, :article, :aside, :footer,
                          :header, :h1, :h2, :h3, :h4, :h5, :h6, :hgroup, :nav, :section,
                          :dd, :div, :dl, :dt, :figcaption, :figure, :li, :main, :ol, :p, :pre, :ul, :span,
                          :a, :abbr, :b, :bdi, :bdo, :cite, :code, :data, :dfn, :em, :i, :kbd, :mark,
                          :q, :rp, :rt, :rtc, :ruby, :s, :samp, :small, :spam, :strong, :sub, :sup, :time,
                          :u, :var, :wrb, :audio, :map, :void, :embed, :object, :canvas, :noscript, :script,
                          :del, :ins, :caption, :col, :colgroup, :table, :tbody, :td, :tfoot, :th, :thead, :tr,
                          :button, :datalist, :fieldset, :form, :label, :legend, :meter, :optgroup, :option,
                          :output, :progress, :select, :textarea, :details, :dialog, :menu, :menuitem, :summary,
                          :slot, :template]
const BOOL_ATTRIBUTES = [:checked, :disabled, :selected]

const FILE_EXT      = ".flax.jl"
const TEMPLATE_EXT  = ".flax.html"

typealias HTMLString String

function attributes(attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: Vector{String}
  a = String[]
  for (k,v) in attrs
    if startswith(v, "<\$") && endswith(v, "\$>")
      v = (replace(replace(replace(v, "<\$", ""), "\$>", ""), "'", "\"") |> strip) |> parse |> eval
    end
    push!(a, "$(k)=\"$(v)\" ")
  end

  a
end

function normal_element(f::Function, elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString
  a = attributes(attrs)
  """\n<$( string(lowercase(elem)) * (! isempty(a) ? (" " * join(a, " ")) : "") )>\n$(join(f()))\n</$( string(lowercase(elem)) )>\n"""
end

function void_element(elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString
  a = attributes(attrs)

  "<$( string(lowercase(elem)) * (! isempty(a) ? (" " * join(a, " ")) : "") )>\n"
end

function include_template(path::String) :: String
  path = relpath(path)
  if Genie.config.flax_compile_templates
    file_path = joinpath(Genie.config.cache_folder, path) * FILE_EXT
    cache_file_name = sha1(path)
    if isfile(file_path)
      return (file_path |> include)()
    else
      flax_code = path |> html_to_flax
      if ! isdir(joinpath(Genie.config.cache_folder, dirname(path)))
        mkpath(joinpath(Genie.config.cache_folder, dirname(path)))
      end
      open(file_path, "w") do io
        write(io, flax_code)
      end
      return (flax_code |> include_string)()
    end
  end

  flax_code = path |> html_to_flax
  (flax_code |> include_string)()
end

function html(resource::Symbol, action::Symbol, layout::Symbol; vars...) :: Dict{Symbol,String}
  try
    task_local_storage(:__vars, Dict(vars))
    task_local_storage(:__yield, include_template(joinpath(Genie.RESOURCE_PATH, string(resource), Renderer.VIEWS_FOLDER, string(action) * TEMPLATE_EXT)))

    Dict{Symbol,AbstractString}(:html => include_template(joinpath(Genie.APP_PATH, Renderer.LAYOUTS_FOLDER, string(layout) * TEMPLATE_EXT)) |> Gumbo.parsehtml |> string |> doc)
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

    task_local_storage(:__vars, Dict(vars))

    if isa(julia_action_template_func, Function)
      task_local_storage(:__yield, julia_action_template_func())
    else
      message = "The Flax view should return a function when including $julia_action_template"
      Logger.log(message, :err)
      Logger.@location

      throw(message)
    end

    return  if isa(julia_layout_template_func, Function)
              Dict{Symbol,AbstractString}(:html => julia_layout_template_func() |> Gumbo.parsehtml |> string |> doc)
            else
              message = "The Flax template should return a function when including $julia_layout_template"
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

function html_to_flax(file_path::String) :: String
  code =  """() -> begin \n"""
  code *= file_path |> parse_template
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

function foreach(f::Function, v::Vector) :: String
  mapreduce(x -> string(f(x)), *, v)
end

function parse_template(file_path::String) :: String
  htmldoc = read_template_file(file_path) |> Gumbo.parsehtml
  parse_tree(htmldoc.root, "", 0)
end

function parse_tree(elem, output, depth) :: String
  if isa(elem, HTMLElement)

    if lowercase(string(tag(elem))) == "script" && in("type", collect(keys(attrs(elem))))
      if attrs(elem)["type"] == "julia/eval"
        if ! isempty(children(elem))
          output *= repeat("\t", depth) * string(children(elem)[1].text) * " \n"
        end
      end
    else
      output *= repeat("\t", depth) * "Flax.$(lowercase(string(tag(elem))))("

      attributes = String[]
      for (k,v) in attrs(elem)
        if startswith(v, "<\$") && endswith(v, "\$>")
          v = (replace(replace(replace(v, "<\$", ""), "\$>", ""), "'", "\"") |> strip) |> parse |> eval
        end

        if in(Symbol(lowercase(k)), BOOL_ATTRIBUTES)
          if v == true || v == "true" || v == :true || v == ":true" || v == ""
            push!(attributes, ":$(Symbol(k)) => \"$k\"") # boolean attributes can have the same value as the attribute -- or be empty
          end
        else
          push!(attributes, ":$(Symbol(k)) => \"$v\"")
        end
      end

      output *= join(attributes, ", ") * ") "

      inner = ""
      if ! isempty(children(elem)) # || in(Symbol(elem), NORMAL_ELEMENTS)
        children_count = size(children(elem))[1]
        output *= " do;[ \n"
        idx = 0
        for child in children(elem)
          idx += 1
          inner *= parse_tree(child, "", depth + 1)
          if idx < children_count
            if ! in("type", collect(keys(attrs(child)))) || ( in("type", collect(keys(attrs(child)))) && (attrs(child)["type"] != "julia/eval") )
              inner = repeat("\t", depth) * inner * " \n"
            end
          end
        end
        output *= inner * "\n " * repeat("\t", depth) * "]end \n"
      end
    end

  elseif isa(elem, HTMLText)
    output *= repeat("\t", depth) * "\"$(elem.text)\""
  end

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

    @eval export $elem
  end

  for elem in VOID_ELEMENTS
    """
      function $elem(attrs::Pair{Symbol,String}...) :: HTMLString
        \"\"\"\$(void_element("$(string(elem))", Pair{Symbol,String}[attrs...]))\"\"\"
      end
    """ |> parse |> eval

    @eval export $elem
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

register_elements()
include_helpers()

d = div

function var_dump(var, html = true) :: String
  iobuffer = IOBuffer()
  show(iobuffer, var)
  content = takebuf_string(iobuffer)

  html ? replace(replace("<code>$content</code>", "\n", "<br>"), " ", "&nbsp;") : content
end

macro vars(key)
  :(task_local_storage(:__vars)[$key])
end
macro yield()
  :(task_local_storage(:__yield))
end

end
