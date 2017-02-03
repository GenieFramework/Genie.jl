module Flax

using Genie, Renderer, Gumbo

export HTMLString, doctype, d

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
const VOID_ELEMENTS   = [:base, :link, :meta, :hr, :br, :area, :img, :track, :param, :source, :input]

const FILE_EXT      = ".flax.jl"
const TEMPLATE_EXT  = ".flax.html"

typealias HTMLString String

function attributes(attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: Vector{String}
  a = String[]
  for (k,v) in attrs
    push!(a, "$(k)=\"$(v)\"")
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

function html(resource::Symbol, action::Symbol, layout::Symbol; vars...) :: Dict{Symbol,AbstractString}
  julia_action_template = abspath(joinpath(Genie.RESOURCE_PATH, string(resource), Renderer.VIEWS_FOLDER, string(action) * TEMPLATE_EXT)) |> wrap_code_in_function
  julia_layout_template = abspath(joinpath(Genie.APP_PATH, Renderer.LAYOUTS_FOLDER, string(layout) * TEMPLATE_EXT)) |> wrap_code_in_function

  print(julia_action_template)
  print(julia_layout_template)

  push!(vars, (:yield!! => include_string(julia_action_template)(Dict(vars))))

  Dict{Symbol,AbstractString}(:html => (include_string(julia_layout_template)(Dict(vars)) |> Gumbo.parsehtml |> string))
end

function flax(resource::Symbol, action::Symbol, layout::Symbol; vars...) :: Dict{Symbol,AbstractString}
  julia_action_template = abspath(joinpath(Genie.RESOURCE_PATH, string(resource), Renderer.VIEWS_FOLDER, string(action) * FILE_EXT))
  julia_layout_template = abspath(joinpath(Genie.APP_PATH, Renderer.LAYOUTS_FOLDER, string(layout) * FILE_EXT))

  push!(vars, (:yield!! => include(julia_action_template)(Dict(vars))))

  Dict{Symbol,AbstractString}(:html => (include(julia_layout_template)(Dict(vars)) |> Gumbo.parsehtml |> string))
end

function wrap_code_in_function(file_path::String) :: String
  code =  """function (_p::Dict) \n"""
  code *= file_path |> parse_template
  code *= """\nend"""

  code
end

function read_template_file(file_path::String) :: String
  html = String[]
  open(file_path) do f
    for line in enumerate(eachline(f))
      if startswith(strip(line[2]), "<%+")
        line = read_template_file(abspath("$(strip(parse_tags(line, true)) * TEMPLATE_EXT)"))
      else
        line = parse_tags(line)
      end

      push!(html, line)
    end
  end

  join(html, "\n")
end

function foreach(f::Function, v::Vector)
  mapreduce(x->string(f(x)), *, v)
end

function parse_template(file_path::String) :: String
  htmldoc = read_template_file(file_path) |> Gumbo.parsehtml
  parse_tree(htmldoc.root, "", 0)
end

function parse_tree(elem, output, depth) :: String
  if isa(elem, HTMLElement)

    if lowercase(string(tag(elem))) == "script" && in("type", collect(keys(attrs(elem))))
      if (attrs(elem)["type"] == "julia/output" || attrs(elem)["type"] == "julia/eval")
        if ! isempty(children(elem))
          output *= repeat("\t", depth) * string(children(elem)[1].text) * " \n"
        end
      end
    else
      output *= repeat("\t", depth) * "Flax.$(uppercase(string(tag(elem))))("

      attributes = String[]
      for (k,v) in attrs(elem)
        push!(attributes, ":$(Symbol(k)) => \"$v\"")
      end

      output *= join(attributes, ", ") * ") "

      inner = ""
      if ! isempty(children(elem)) # || in(Symbol(elem), NORMAL_ELEMENTS)
        children_count = size(children(elem))[1]
        output *= " do \n"
        idx = 0
        for child in children(elem)
          idx += 1
          inner *= parse_tree(child, "", depth + 1)
          if idx < children_count
            if ! in("type", collect(keys(attrs(child)))) || ( in("type", collect(keys(attrs(child)))) && (attrs(child)["type"] != "julia/eval") )
              inner = repeat("\t", depth) * inner * " * \n"
            end
          end
        end
        output *= inner * "\n " * repeat("\t", depth) * "end \n"
      end
    end

  elseif isa(elem, HTMLText)
    output *= repeat("\t", depth) * "\"$(elem.text)\""
  end

  output
end

function parse_tags(line::Tuple{Int64,String}, strip_close_tag = false) :: String
  code = line[2]

  code = replace(code, "<%+", "")

  code = replace(code, "<%=", """<script type="julia/output"> ( """)
  code = replace(code, "=%>", strip_close_tag ? " |> string ) " : """ |> string ) </script>""")

  code = replace(code, "<%:", """<script type="julia/eval">""")
  code = replace(code, ":%>", strip_close_tag ? "\n" : """</script>""")

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

register_elements()

d = div

end
