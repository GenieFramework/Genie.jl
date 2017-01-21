module Flax

export HTMLString, doc

const NORMAL_ELEMENTS = [ :html, :head, :body, :title, :style, :address, :article, :aside, :footer,
                          :header, :h1, :h2, :h3, :h4, :h5, :h6, :hgroup, :nav, :section,
                          :dd, :div, :dl, :dt, :figcaption, :figure, :li, :main, :ol, :p, :pre, :ul,
                          :a, :abbr, :b, :bdi, :bdo, :cite, :code, :data, :dfn, :em, :i, :kbd, :mark,
                          :q, :rp, :rt, :rtc, :ruby, :s, :samp, :small, :span, :strong, :sub, :sup, :time,
                          :u, :var, :wrb, :audio, :map, :void, :embed, :object, :canvas, :noscript, :script,
                          :del, :ins, :caption, :col, :colgroup, :table, :tbody, :td, :tfoot, :th, :thead, :tr,
                          :button, :datalist, :fieldset, :form, :label, :legend, :meter, :optgroup, :option,
                          :output, :progress, :select, :textarea, :details, :dialog, :menu, :menuitem, :summary,
                          :slot, :template]
const VOID_ELEMENTS   = [:base, :link, :meta, :hr, :br, :area, :img, :track, :param, :source, :input]

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

  """\n<$( string(elem) * (! isempty(a) ? (" " * join(a, " ")) : "") )>\n$(f())\n</$( string(elem) )>"""
end

function void_element(elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString
  a = attributes(attrs)

  "<$( string(elem) * (! isempty(a) ? (" " * join(a, " ")) : "") )>"
end

function block(args...)
  output = ""
  for a in args
    if isa(a, Function)
      output *= string(a())
    else
      output *= string(a)
    end
  end

  output
end

function doc()
  "<!DOCTYPE html>"
end
function doc(html::String)
  doc() * "\n" * html
end

function register_elements()
  for elem in NORMAL_ELEMENTS
    f_body = """
      function $elem(f::Function = ()->"", attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString
        \"\"\"\$(normal_element(f, "$(string(elem))", attrs))\"\"\"
      end
    """

    f_body |> parse |> eval

    f_body = """
      function $elem(f::Function = ()->"", attrs::Pair{Symbol,String}...) :: HTMLString
        \"\"\"\$($elem(f, [attrs...]))\"\"\"
      end
    """

    f_body |> parse |> eval
  end

  for elem in VOID_ELEMENTS
    f_body = """
      function $elem(attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString
        \"\"\"\$(void_element("$(string(elem))", attrs))\"\"\"
      end
    """

    f_body |> parse |> eval

    f_body = """
      function $elem(attrs::Pair{Symbol,String}...) :: HTMLString
        \"\"\"\$($elem([attrs...]))\"\"\"
      end
    """

    f_body |> parse |> eval
  end
end

register_elements()

end

function import_elements()
  for elem in vcat(Flax.NORMAL_ELEMENTS, Flax.VOID_ELEMENTS)
    "import Flax.$elem" |> parse |> eval
  end
end

import_elements()
