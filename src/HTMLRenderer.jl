module HTMLRenderer


import Revise
import Markdown, Logging, FilePaths, Gumbo
using Genie, Genie.Flax


const HTML_FILE_EXT      = [".flax.jl", "html.jl"]
const TEMPLATE_EXT  = [".flax.html", ".jl.html"]
const MARKDOWN_FILE_EXT = [".md", ".jl.md"]

const SUPPORTED_HTML_OUTPUT_FILE_FORMATS = TEMPLATE_EXT

const HTMLString = String
const HTMLParser = Gumbo

const MD_SEPARATOR_START = "---\n"
const MD_SEPARATOR_END   = "---\n"

const NBSP_REPLACEMENT = ("&nbsp;"=>"!!nbsp;;")

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

export HTMLString


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
  replace(string(lowercase(elem)), "_"=>"-")
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

  extension in HTML_FILE_EXT && return (() -> Base.include(context, path))

  f_name = Flax.function_name(path) |> Symbol
  mod_name = Flax.m_name(string(path, partial)) * ".jl"
  f_path = joinpath(Genie.BUILD_PATH, Flax.BUILD_NAME, mod_name)
  f_stale = Flax.build_is_stale(path, f_path)

  if f_stale || ! isdefined(context, f_name)
    content = if extension in MARKDOWN_FILE_EXT
      vars_injection, md = include_markdown(path, context = context)
      Flax.string_to_flax(md, partial = partial, f_name = f_name, prepend = vars_injection)
    else
      Flax.html_to_flax(path, partial = partial)
    end

    f_stale && Flax.build_module(content, path, mod_name)

    return Base.include(context, joinpath(Genie.BUILD_PATH, Flax.BUILD_NAME, mod_name))
  end

  getfield(context, f_name)
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
    render(resource::Union{Symbol,String}, action::Union{Symbol,String}; layout::Union{Symbol,String} = Genie.config.renderer_default_layout_file, context::Module = @__MODULE__, vars...) :: Function

Renders data as HTML
"""
function render(resource::Union{Symbol,String}, action::Union{Symbol,String}; layout::Union{Symbol,String} = Genie.config.renderer_default_layout_file, context::Module = @__MODULE__, vars...) :: Function
  render(FilePaths.Path(joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action)));
                  layout = FilePaths.Path(joinpath(Genie.APP_PATH, Genie.LAYOUTS_FOLDER, string(layout))),
                  context = context, vars...)
end


"""
"""
function render(data::String; context::Module = @__MODULE__, layout::Union{String,Nothing} = nothing, vars...) :: Function
  Flax.registervars(vars...)

  if layout !== nothing
    task_local_storage(:__yield, Flax.parseview(data, partial = true, context = context))
    Flax.parseview(layout, partial = false, context = context)
  else
    Flax.parseview(data, partial = false, context = context)
  end
end


"""
"""
function render(viewfile::FilePaths.PosixPath; layout::Union{Nothing,FilePaths.PosixPath} = nothing, context::Module = @__MODULE__, vars...) :: Function
  Flax.registervars(vars...)

  if layout !== nothing
    task_local_storage(:__yield, get_template(string(viewfile), partial = true, context = context))
    get_template(string(layout), partial = false, context = context)
  else
    get_template(string(viewfile), partial = false, context = context)
  end
end


function parsehtml(input::String; partial::Bool = true) :: String
  parsehtml(HTMLParser.parsehtml(replace(input, NBSP_REPLACEMENT)).root, 0, partial = partial)
end


"""
    parsehtml(elem, output, depth; partial = true) :: String

Parses a HTML tree structure into a `string` of Flax code.
"""
function parsehtml(elem::HTMLParser.HTMLElement, depth::Int = 0; partial::Bool = true) :: String
  io = IOBuffer()

  tag_name = replace(lowercase(string(HTMLParser.tag(elem))), "-"=>"_")

  invalid_tag = partial && (tag_name == "html" || tag_name == "head" || tag_name == "body")

  if tag_name == "script" && in("type", collect(keys(HTMLParser.attrs(elem))))
    if HTMLParser.attrs(elem)["type"] == "julia/eval"
      isempty(HTMLParser.children(elem)) || print(io, repeat("\t", depth), string(HTMLParser.children(elem)[1].text), "\n")
    end

  else
    print(io, repeat("\t", depth), ( ! invalid_tag ? "Html.$(tag_name)(" : "Html.HTMLRenderer.skip_element(" ))

    attributes = IOBuffer()
    for (k,v) in HTMLParser.attrs(elem)
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
    print(io, attributes_string, ")")

    inner = ""
    if ! isempty(HTMLParser.children(elem))
      children_count = size(HTMLParser.children(elem))[1]

      print(io, " do;[\n")

      idx = 0
      for child in HTMLParser.children(elem)
        idx += 1
        inner *= isa(child, HTMLParser.HTMLText) ? parsehtml(child, depth + 1) : parsehtml(child, depth + 1, partial = partial)
        if idx < children_count
          if  ( isa(child, HTMLParser.HTMLText) ) ||
              ( isa(child, HTMLParser.HTMLElement) &&
              ( ! in("type", collect(keys(HTMLParser.attrs(child)))) ||
                ( in("type", collect(keys(HTMLParser.attrs(child)))) && (HTMLParser.attrs(child)["type"] != "julia/eval") ) ) )
              isempty(inner) || (inner = string(repeat("\t", depth), inner, "\n"))
          end
        end
      end

      if ! isempty(inner)
        endswith(inner, "\n\n") && (inner = inner[1:end-2])
        print(io, inner, repeat("\t", depth))
      end

      print(io, "]end\n")
    end

  end

  String(take!(io))
end


function parsehtml(elem::HTMLParser.HTMLText, depth::Int = 0; partial::Bool = true) :: String
  content = elem.text
  endswith(content, "\"") && (content *= Char(0x0))
  content = replace(content, NBSP_REPLACEMENT[2]=>NBSP_REPLACEMENT[1])
  string(repeat("\t", depth), "\"\"\"$(content)\"\"\"")
end

end