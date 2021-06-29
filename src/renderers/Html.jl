module Html

import Markdown, Logging, Gumbo, Reexport, OrderedCollections, Millboard, HTTP, YAML

Reexport.@reexport using Genie

import Genie.Renderer
import Genie.Renderer: vars
Reexport.@reexport using HttpCommon


const DEFAULT_LAYOUT_FILE = :app
const LAYOUTS_FOLDER = "layouts"

const HTML_FILE_EXT = "html.jl"
const TEMPLATE_EXT  = ".jl.html"
const MARKDOWN_FILE_EXT = [".md", ".jl.md"]

const SUPPORTED_HTML_OUTPUT_FILE_FORMATS = [TEMPLATE_EXT]

const HTMLString = String
const HTMLParser = Gumbo

const NBSP_REPLACEMENT = ("&nbsp;"=>"!!nbsp;;")

const NORMAL_ELEMENTS = [ :html, :head, :body, :title, :style, :address, :article, :aside, :footer,
                          :header, :h1, :h2, :h3, :h4, :h5, :h6, :hgroup, :nav, :section,
                          :dd, :div, :d, :dl, :dt, :figcaption, :figure, :li, :main, :ol, :p, :pre, :ul, :span,
                          :a, :abbr, :b, :bdi, :bdo, :cite, :code, :data, :dfn, :em, :i, :kbd, :mark,
                          :q, :rp, :rt, :rtc, :ruby, :s, :samp, :small, :spam, :strong, :sub, :sup, :time,
                          :u, :var, :wrb, :audio, :void, :embed, :object, :canvas, :noscript, :script,
                          :del, :ins, :caption, :col, :colgroup, :table, :tbody, :td, :tfoot, :th, :thead, :tr,
                          :button, :datalist, :fieldset, :label, :legend, :meter,
                          :output, :progress, :select, :option, :textarea, :details, :dialog, :menu, :menuitem, :summary,
                          :slot, :template, :blockquote, :center, :iframe] #TODO: Gumbo has a problem and strips away <template>
const VOID_ELEMENTS   = [:base, :link, :meta, :hr, :br, :area, :img, :track, :param, :source, :input]
const CUSTOM_ELEMENTS = [:form, :select]
const NON_EXPORTED = [:main, :map, :filter]
const SVG_ELEMENTS = [:animate, :circle, :animateMotion, :animateTransform, :clipPath, :defs, :desc, :discard,
                      :ellipse, :feComponentTransfer, :feComposite, :feDiffuseLighting, :feBlend, :feColorMatrix,
                      :feConvolveMatrix, :feDisplacementMap, :feDistantLight, :feDropShadow, :feFlood, :feFuncA, :feFuncB, :feFuncG,
                      :feFuncR, :feGaussianBlur, :feImage, :feMerge, :feMergeNode, :feMorphology, :feOffset, :fePointLight, :feSpecularLighting,
                      :feSpotLight, :feTile, :feTurbulence, :foreignObject, :g, :hatch, :hatchpath, :image, :line, :linearGradient,
                      :marker, :mask, :metadata, :mpath, :path, :pattern, :polygon, :polyline, :radialGradient, :rect, :set, :stop, :svg,
                      :switch, :symbol, :text, :textPath, :tspan, :use, :view]

const EMBEDDED_JULIA_PLACEHOLDER = "~~~~~|~~~~~"


export HTMLString, html, doc, doctype
export @yield, collection, view!, for_each
export partial, template


task_local_storage(:__yield, "")


include("MdHtml.jl")


"""
    normal_element(f::Function, elem::String, attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString

Generates a HTML element in the form <...></...>
"""
function normal_element(f::Function, elem::Any, args::Vector = [], attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  normal_element(f(), string(elem), args, attrs...)
end
function normal_element(children::Union{String,Vector{String}}, elem::Any, args::Vector, attrs::Pair{Symbol,Any}) :: HTMLString
  normal_element(children, string(elem), args, Pair{Symbol,Any}[attrs])
end
function normal_element(children::Tuple, elem::Any, args::Vector, attrs::Pair{Symbol,Any}) :: HTMLString
  normal_element([children...], string(elem), args, Pair{Symbol,Any}[attrs])
end
function normal_element(children::Union{String,Vector{String}}, elem::Any, args::Vector, attrs...) :: HTMLString
  normal_element(children, string(elem), args, Pair{Symbol,Any}[attrs...])
end
function normal_element(children::Union{String,Vector{String}}, elem::Any, args::Vector = [], attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  children = join(children)

  idx = findfirst(x -> x == :inner, getindex.(attrs, 1))
  if !isnothing(idx)
    children *= join(attrs[idx][2])
    deleteat!(attrs, idx)
  end

  ii = (x -> x isa Symbol && occursin(Genie.config.html_parser_char_dash, "$x")).(args)
  args[ii] .= Symbol.(replace.(string.(args[ii]), Ref(Genie.config.html_parser_char_dash=>"-")))

  elem = normalize_element(string(elem))
  attribs = rstrip(attributes(attrs))
  string("<", elem, (isempty(attribs) ? "" : " $attribs"), (isempty(args) ? "" : " $(join(args, " "))"), ">", prepare_template(children), "</", elem, ">")
end
function normal_element(elem::Any, attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  normal_element("", string(elem), attrs...)
end
function normal_element(elems::Vector, elem::Any, args = [], attrs...) :: HTMLString
  io = IOBuffer()

  for e in elems
    e === nothing && continue

    if isa(e, Vector)
      print(io, join(e))
    elseif isa(e, Function)
      print(io, e(), "\n")
    else
      print(io, e, "\n")
    end
  end

  normal_element(String(take!(io)), string(elem), args, attrs...)
end
function normal_element(_::Nothing, __::Any) :: HTMLString
  ""
end
function normal_element(children::Vector{T} where T, elem::Any, args::Vector{T} where T) :: HTMLString
  normal_element(join([(isa(f, Function) ? f() : string(f)) for f in children]), elem, args)
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
    v === nothing && continue # skip nothing values

    print(a, attrparser(k, v))
  end

  String(take!(a))
end


function attrparser(k::Symbol, v::Bool) :: String
  v ? "$(k |> parseattr) " : default_attrparser(k, v)
end

function attrparser(k::Symbol, v::Union{AbstractString,Symbol}) :: String
  isempty(string(v)) && return attrparser(k, true)
  "$(k |> parseattr)=\"$(v)\" "
end

function attrparser(k::Symbol, v::Any) :: String
  default_attrparser(k, v)
end

function default_attrparser(k::Symbol, v::Any) :: String
  "$(k |> parseattr)=$(v) "
end


"""
    parseattr(attr) :: String

Converts Julia keyword arguments to HTML attributes with illegal Julia chars.
"""
function parseattr(attr) :: String
  attr = string(attr)
  endswith(attr, Genie.config.html_parser_char_at) && (attr = string("@", attr[1:end-(length(Genie.config.html_parser_char_at))]))
  endswith(attr, Genie.config.html_parser_char_column) && (attr = string(":", attr[1:end-(length(Genie.config.html_parser_char_column))]))

  attr = replace(attr, Regex(Genie.config.html_parser_char_dash)=>"-")
  attr = replace(attr, Regex(Genie.config.html_parser_char_column * Genie.config.html_parser_char_column)=>":")
  replace(attr, Regex(Genie.config.html_parser_char_dot)=>".")
end


"""
    normalize_element(elem::String)

Cleans up problematic characters or DOM elements.
"""
function normalize_element(elem::String) :: String
  replace(elem, Genie.config.html_parser_char_dash=>"-")
end


"""
    denormalize_element(elem::String)

Replaces `-` with the char defined to replace dashes, as Julia does not support them in names.
"""
function denormalize_element(elem::String) :: String
  uppercase(elem) == elem && (elem = lowercase(elem))
  elem = replace(elem, "-"=>Genie.config.html_parser_char_dash)
  endswith(elem, "_") ? elem[1:end-1] : elem
end


"""
    void_element(elem::String, attrs::Vector{Pair{Symbol,String}} = Vector{Pair{Symbol,String}}()) :: HTMLString

Generates a void HTML element in the form <...>
"""
function void_element(elem::String, args = [], attrs::Vector{Pair{Symbol,Any}} = Pair{Symbol,Any}[]) :: HTMLString
  attribs = rstrip(attributes(attrs))
  string("<", normalize_element(elem), (isempty(attribs) ? "" : " $attribs"), (isempty(args) ? "" : " $(join(args, " "))"), Genie.config.html_parser_close_tag, ">")
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
    get_template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: Function

Resolves the inclusion and rendering of a template file
"""
function get_template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: Function
  path, extension = Genie.Renderer.view_file_info(path, SUPPORTED_HTML_OUTPUT_FILE_FORMATS)

  extension == HTML_FILE_EXT && return (() -> Base.include(context, path))

  f_name = Genie.Renderer.function_name(string(path, partial)) |> Symbol
  mod_name = Genie.Renderer.m_name(string(path, partial)) * ".jl"
  f_path = joinpath(Genie.config.path_build, Genie.Renderer.BUILD_NAME, mod_name)
  f_stale = Genie.Renderer.build_is_stale(path, f_path)

  if f_stale || ! isdefined(context, f_name)
    if extension in MARKDOWN_FILE_EXT
      path = MdHtml.md_to_html(path, context = context)
    end

    f_stale && Genie.Renderer.build_module(html_to_julia(path, partial = partial), path, mod_name)

    return Base.include(context, joinpath(Genie.config.path_build, Genie.Renderer.BUILD_NAME, mod_name))
  end

  getfield(context, f_name)
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
    parseview(data::String; partial = false, context::Module = @__MODULE__) :: Function

Parses a view file, returning a rendering function. If necessary, the function is JIT-compiled, persisted and loaded into memory.
"""
function parseview(data::String; partial = false, context::Module = @__MODULE__) :: Function
  data_hash = hash(data)
  path = "Genie_" * string(data_hash)

  func_name = Genie.Renderer.function_name(string(data_hash, partial)) |> Symbol
  mod_name = Genie.Renderer.m_name(string(path, partial)) * ".jl"
  f_path = joinpath(Genie.config.path_build, Genie.Renderer.BUILD_NAME, mod_name)
  f_stale = Genie.Renderer.build_is_stale(f_path, f_path)

  if f_stale || ! isdefined(context, func_name)
    if f_stale
      Genie.Renderer.build_module(string_to_julia(data, partial = partial), path, mod_name)
    end

    return Base.include(context, joinpath(Genie.config.path_build, Genie.Renderer.BUILD_NAME, mod_name))
  end

  getfield(context, func_name)
end


"""
    render(data::String; context::Module = @__MODULE__, layout::Union{String,Nothing} = nothing, vars...) :: Function

Renders the string as an HTML view.
"""
function render(data::String; context::Module = @__MODULE__, layout::Union{String,Nothing} = nothing, vars...) :: Function
  Genie.Renderer.registervars(; context = context, vars...)

  if layout !== nothing
    task_local_storage(:__yield, parseview(data, partial = true, context = context))
    parseview(layout, partial = false, context = context)
  else
    parseview(data, partial = false, context = context)
  end
end


"""
    render(viewfile::Genie.Renderer.FilePath; layout::Union{Nothing,Genie.Renderer.FilePath} = nothing, context::Module = @__MODULE__, vars...) :: Function

Renders the template file as an HTML view.
"""
function render(viewfile::Genie.Renderer.FilePath; layout::Union{Nothing,Genie.Renderer.FilePath} = nothing, context::Module = @__MODULE__, vars...) :: Function
  Genie.Renderer.registervars(; context = context, vars...)

  if layout !== nothing
    task_local_storage(:__yield, get_template(string(viewfile), partial = true, context = context))
    get_template(string(layout), partial = false, context = context)
  else
    get_template(string(viewfile), partial = false, context = context)
  end
end


"""
    parsehtml(input::String; partial::Bool = true) :: String


"""
function parsehtml(input::String; partial::Bool = true) :: String
  parsehtml(
    HTMLParser.parsehtml(replace(input, NBSP_REPLACEMENT), preserve_whitespace = false).root,
    0, partial = partial)
end


function Genie.Renderer.render(::Type{MIME"text/html"}, data::String; context::Module = @__MODULE__, layout::Union{String,Nothing} = nothing, vars...) :: Genie.Renderer.WebRenderable
  try
    render(data; context = context, layout = layout, vars...) |> Genie.Renderer.WebRenderable
  catch ex
    isa(ex, KeyError) && Genie.Renderer.changebuilds() # it's a view error so don't reuse them
    rethrow(ex)
  end
end


function Genie.Renderer.render(::Type{MIME"text/html"}, viewfile::Genie.Renderer.FilePath; layout::Union{Nothing,Genie.Renderer.FilePath} = nothing, context::Module = @__MODULE__, vars...) :: Genie.Renderer.WebRenderable
  try
    render(viewfile; layout = layout, context = context, vars...) |> Genie.Renderer.WebRenderable
  catch ex
    isa(ex, KeyError) && Genie.Renderer.changebuilds() # it's a view error so don't reuse them
    rethrow(ex)
  end
end


function html(resource::Genie.Renderer.ResourcePath, action::Genie.Renderer.ResourcePath; layout::Genie.Renderer.ResourcePath = DEFAULT_LAYOUT_FILE,
                context::Module = @__MODULE__, status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders(), vars...) :: Genie.Renderer.HTTP.Response
  html(Genie.Renderer.Path(joinpath(Genie.config.path_resources, string(resource), Renderer.VIEWS_FOLDER, string(action)));
        layout = Genie.Renderer.Path(joinpath(Genie.config.path_app, LAYOUTS_FOLDER, string(layout))),
        context = context, status = status, headers = headers, vars...)
end


"""
    html(data::String; context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), layout::Union{String,Nothing} = nothing, vars...) :: HTTP.Response

Parses the `data` input as HTML, returning a HTML HTTP Response.

# Arguments
- `data::String`: the HTML string to be rendered
- `context::Module`: the module in which the variables are evaluated (in order to provide the scope for vars). Usually the controller.
- `status::Int`: status code of the response
- `headers::HTTPHeaders`: HTTP response headers
- `layout::Union{String,Nothing}`: layout file for rendering `data`

# Example
```jldoctest
julia> html("<h1>Welcome \$(vars(:name))</h1>", layout = "<div><% @yield %></div>", name = "Adrian")
HTTP.Messages.Response:
"
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8

<html><head></head><body><div><h1>Welcome Adrian</h1>
</div></body></html>"
```
"""
function html(data::String; context::Module = @__MODULE__, status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders(),
                            layout::Union{String,Nothing,Genie.Renderer.FilePath} = nothing, forceparse::Bool = false, vars...) :: Genie.Renderer.HTTP.Response
  isa(layout, Genie.Renderer.FilePath) && (layout = read(layout, String))

  if occursin(raw"$", data) || occursin("<%", data) || layout !== nothing || forceparse
    Genie.Renderer.WebRenderable(Genie.Renderer.render(MIME"text/html", data; context = context, layout = layout, vars...), status, headers) |> Genie.Renderer.respond
  else
    Genie.Renderer.WebRenderable(body = data, status = status, headers = headers) |> Genie.Renderer.respond
  end
end


"""
    html(md::Markdown.MD; context::Module = @__MODULE__, status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders(), layout::Union{String,Nothing} = nothing, forceparse::Bool = false, vars...) :: Genie.Renderer.HTTP.Response

Markdown view rendering
"""
function html(md::Markdown.MD; context::Module = @__MODULE__, status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders(), layout::Union{String,Nothing} = nothing, forceparse::Bool = false, vars...) :: Genie.Renderer.HTTP.Response
  data = MdHtml.eval_markdown(string(md)) |> Markdown.parse |> Markdown.html
  for kv in vars
    data = replace(data, ":" * string(kv[1]) => "\$" * string(kv[1]))
  end

  html(data; context = context, status = status, headers = headers, layout = layout, forceparse = forceparse, vars...)
end


"""
    html(viewfile::FilePath; layout::Union{Nothing,FilePath} = nothing,
          context::Module = @__MODULE__, status::Int = 200, headers::HTTPHeaders = HTTPHeaders(), vars...) :: HTTP.Response

Parses and renders the HTML `viewfile`, optionally rendering it within the `layout` file. Valid file format is `.html.jl`.

# Arguments
- `viewfile::FilePath`: filesystem path to the view file as a `Renderer.FilePath`, ie `Renderer.FilePath("/path/to/file.html.jl")`
- `layout::FilePath`: filesystem path to the layout file as a `Renderer.FilePath`, ie `Renderer.FilePath("/path/to/file.html.jl")`
- `context::Module`: the module in which the variables are evaluated (in order to provide the scope for vars). Usually the controller.
- `status::Int`: status code of the response
- `headers::HTTPHeaders`: HTTP response headers
"""
function html(viewfile::Genie.Renderer.FilePath; layout::Union{Nothing,Genie.Renderer.FilePath} = nothing,
                context::Module = @__MODULE__, status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders(), vars...) :: Genie.Renderer.HTTP.Response
  Genie.Renderer.WebRenderable(Genie.Renderer.render(MIME"text/html", viewfile; layout = layout, context = context, vars...), status, headers) |> Genie.Renderer.respond
end


"""
    safe_attr(attr) :: String

Replaces illegal Julia characters from HTML attributes with safe ones, to be used as keyword arguments.
"""
function safe_attr(attr) :: String
  attr = string(attr)

  occursin("-", attr) && replace!(attr, "-"=>Genie.config.html_parser_char_dash)
  occursin(":", attr) && replace!(attr, ":"=>Genie.config.html_parser_char_column)
  occursin("@", attr) && replace!(attr, "@"=>Genie.config.html_parser_char_at)
  occursin(".", attr) && replace!(attr, "."=>Genie.config.html_parser_char_dot)

  attr
end


"""
    parsehtml(elem, output, depth; partial = true) :: String

Parses a HTML tree structure into a `string` of Julia code.
"""
function parsehtml(elem::HTMLParser.HTMLElement, depth::Int = 0; partial::Bool = true) :: String
  io = IOBuffer()

  tag_name = denormalize_element(string(HTMLParser.tag(elem)))

  invalid_tag = partial && (tag_name == "html" || tag_name == "head" || tag_name == "body")

  if tag_name == "script" && in("type", collect(keys(HTMLParser.attrs(elem)))) && HTMLParser.attrs(elem)["type"] == "julia/eval"
    isempty(HTMLParser.children(elem)) || print(io, repeat("\t", depth), string(HTMLParser.children(elem)[1].text), "\n")
  else
    mdl = isdefined(@__MODULE__, Symbol(tag_name)) ? string(@__MODULE__, ".") : ""
    print(io, repeat("\t", depth), ( ! invalid_tag ? "$mdl$(tag_name)(" : "Html.skip_element(" ))

    attributes = IOBuffer()
    attributes_keys = String[]
    attributes_values = String[]

    for (k,v) in HTMLParser.attrs(elem)
      # x = v
      k = string(k) |> lowercase
      if occursin("\"", v)
        # we need to escape double quotes but only if it's not embedded Julia code
        mx = collect(eachmatch(r"\$\((.*?)\)|<%(.*?)%>", string(v)))
        if ! isempty(mx)
          index = 1
          for value in mx
            value === nothing && continue

            label = "$(EMBEDDED_JULIA_PLACEHOLDER)_$(index)"
            v = replace(string(v), value.match => label)
            index += 1
          end

          if occursin("\"", v) # do we still need to escape double quotes?
            v = replace(string(v), "\"" => "\\\"") # we need to escape " as this will be inside julia strings
          end

          # now we need to put back the embedded Julia
          index = 1
          for value in mx
            value === nothing && continue

            label = "$(EMBEDDED_JULIA_PLACEHOLDER)_$(index)"
            v = replace(string(v), label => value.match)
            index += 1
          end
        end
      end

      if startswith(k, raw"$") # do not process embedded julia code
        print(attributes, k[2:end], ", ") # strip the $, this is rendered directly in Julia code
        continue
      end

      if occursin("-", k) ||
          occursin(":", k) ||
          occursin("@", k) ||
          occursin(".", k) ||
          occursin("for", k)

        push!(attributes_keys, Symbol(k) |> repr)

        v = string(v) |> repr
        occursin(raw"\$", v) && (v = replace(v, raw"\$"=>raw"$"))
        push!(attributes_values, v)
      else
        print(attributes, """$k="$v" """, ", ")
      end
    end

    attributes_string = String(take!(attributes))
    endswith(attributes_string, ", ") && (attributes_string = attributes_string[1:end-2])

    print(io, attributes_string)
    ! isempty(attributes_string) && ! isempty(attributes_keys) && print(io, ", ")
    ! isempty(attributes_keys) &&
      print(io, "; NamedTuple{($(join(attributes_keys, ", "))$(length(attributes_keys) == 1 ? ", " : ""))}(($(join(attributes_values, ", "))$(length(attributes_keys) == 1 ? ", " : "")))...")
    print(io, ")")

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

      print(io, "; ]end\n")
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


"""
    html_to_julia(file_path::String; partial = true) :: String

Converts a HTML document to Julia code.
"""
function html_to_julia(file_path::String; partial = true) :: String
  to_julia(file_path, parse_template, partial = partial)
end


"""
    string_to_julia(content::String; partial = true, f_name::Union{Symbol,Nothing} = nothing, prepend = "") :: String

Converts string view data to Julia code
"""
function string_to_julia(content::String; partial = true, f_name::Union{Symbol,Nothing} = nothing, prepend::String = "\n") :: String
  to_julia(content, parse_string, partial = partial, f_name = f_name, prepend = prepend)
end


"""
    to_julia(input::String, f::Function; partial = true, f_name::Union{Symbol,Nothing} = nothing, prepend = "") :: String

Converts an input file to Julia code
"""
  function to_julia(input::String, f::Union{Function,Nothing};
                  partial = true, f_name::Union{Symbol,Nothing} = nothing, prepend::String = "\n") :: String
  f_name = (f_name === nothing) ? Genie.Renderer.function_name(string(input, partial)) : f_name

  string("function $(f_name)(; $(Genie.Renderer.injectkwvars())) \n",
          prepend,
          (partial ? "" : "\nGenie.Renderer.Html.doctype() * \n"),
          f !== nothing ? f(input; partial = partial) : input,
          "\nend \n")
end


"""
    partial(path::String; context::Module = @__MODULE__, vars...) :: String

Renders (includes) a view partial within a larger view or layout file.
"""
function partial(path::String; context::Module = @__MODULE__, kwvars...) :: String
  for (k,v) in kwvars
    vars()[k] = v
  end

  template(path, partial = true, context = context)
end


"""
    template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: String

Renders a template file.
"""
function template(path::String; partial::Bool = true, context::Module = @__MODULE__) :: String
  try
    get_template(path, partial = partial, context = context)()
  catch ex
    if isa(ex, MethodError) && (string(ex.f) == "get_template" || startswith(string(ex.f), "func_"))
      Base.invokelatest(get_template(path, partial = partial, context = context))::String
    else
      rethrow(ex)
    end
  end
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

Parses a HTML file into Julia code.
"""
function parse_template(file_path::String; partial::Bool = true) :: String
  parse(read_template_file(file_path)::String; partial = partial)
end


"""
    parse_string(data::String; partial = true) :: String

Parses a HTML string into Julia code.
"""
function parse_string(data::String; partial::Bool = true) :: String
  parse(parsetags(data), partial = partial)
end


function parse(input::String; partial::Bool = true) :: String
  parsehtml(input, partial = partial)
end


"""
    parsetags(line::Tuple{Int,String}, strip_close_tag = false) :: String

Parses special HTML+Julia tags.
"""
function parsetags(line::Tuple{Int,String}) :: String
  parsetags(line[2])
end


function parsetags(code::String) :: String
  replace(
    replace(code, "<%"=>"""<script type="julia/eval">"""),
    "%>"=>"""</script>""")
end


"""
    register_elements() :: Nothing

Generated functions that represent Julia functions definitions corresponding to HTML elements.
"""
function register_elements(; context = @__MODULE__) :: Nothing
  for elem in NORMAL_ELEMENTS
    register_normal_element(elem)
  end

  for elem in VOID_ELEMENTS
    register_void_element(elem)
  end

  for elem in CUSTOM_ELEMENTS
    Core.eval(@__MODULE__, """include("html/$elem.jl")""" |> Meta.parse)
    elem in NON_EXPORTED || Core.eval(context, "export $elem" |> Meta.parse)
  end

  for elem in SVG_ELEMENTS
    register_normal_element(elem)
  end

  nothing
end


"""
    register_element(elem::Union{Symbol,String}, elem_type::Union{Symbol,String} = :normal; context = @__MODULE__) :: Nothing

Generates a Julia function representing an HTML element.
"""
function register_element(elem::Union{Symbol,String}, elem_type::Union{Symbol,String} = :normal; context = @__MODULE__) :: Nothing
  elem = string(elem)
  occursin("-", elem) && (elem = denormalize_element(elem))

  elem_type == :normal ? register_normal_element(elem) : register_void_element(elem)
end


"""
    register_normal_element(elem::Union{Symbol,String}; context = @__MODULE__) :: Nothing

Generates a Julia function representing a "normal" HTML element: that is an element with a closing tag, <tag>...</tag>
"""
function register_normal_element(elem::Union{Symbol,String}; context = @__MODULE__) :: Nothing
  Core.eval(context, """
    function $elem(f::Function, args...; attrs...) :: HTMLString
      \"\"\"\$(normal_element(f, "$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  Core.eval(context, """
    function $elem(children::Union{String,Vector{String}} = "", args...; attrs...) :: HTMLString
      \"\"\"\$(normal_element(children, "$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  Core.eval(context, """
    function $elem(children::Any, args...; attrs...) :: HTMLString
      \"\"\"\$(normal_element(string(children), "$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  Core.eval(context, """
    function $elem(children::Vector{Any}, args...; attrs...) :: HTMLString
      \"\"\"\$(normal_element([string(c) for c in children], "$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  elem in NON_EXPORTED || Core.eval(context, "export $elem" |> Meta.parse)

  nothing
end


"""
    register_void_element(elem::Union{Symbol,String}; context::Module = @__MODULE__) :: Nothing

Generates a Julia function representing a "void" HTML element: that is an element without a closing tag, <tag />
"""
function register_void_element(elem::Union{Symbol,String}; context::Module = @__MODULE__) :: Nothing
  Core.eval(context, """
    function $elem(args...; attrs...) :: HTMLString
      \"\"\"\$(void_element("$(string(elem))", [args...], Pair{Symbol,Any}[attrs...]))\"\"\"
    end
  """ |> Meta.parse)

  elem in NON_EXPORTED || Core.eval(context, "export $elem" |> Meta.parse)

  nothing
end


"""
    for_each(f::Function, v)

Iterates over the `v` Vector and applies function `f` for each element.
The results of each iteration are concatenated and the final string is returned.
"""
function for_each(f::Function, v)
  [f(x) for x in v] |> join
end


"""
    collection(template::Function, collection::Vector{T})::String where {T}

Creates a view fragment by repeateadly applying a function to each element of the collection.
"""
function collection(template::Function, collection::Vector{T})::String where {T}
  for_each(collection) do item
    template(item) |> string
  end
end


### === ###
### EXCEPTIONS ###


"""
    Genie.Router.error(error_message::String, ::Type{MIME"text/html"}, ::Val{500}; error_info::String = "") :: HTTP.Response

Returns a 500 error response as an HTML doc.
"""
function Genie.Router.error(error_message::String, ::Type{MIME"text/html"}, ::Val{500}; error_info::String = "") :: HTTP.Response
  serve_error_file(500, error_message, error_info = error_info)
end


"""
    Genie.Router.error(error_message::String, ::Type{MIME"text/html"}, ::Val{404}; error_info::String = "") :: HTTP.Response

Returns a 404 error response as an HTML doc.
"""
function Genie.Router.error(error_message::String, ::Type{MIME"text/html"}, ::Val{404}; error_info::String = "") :: HTTP.Response
  serve_error_file(404, error_message, error_info = error_info)
end


"""
    Genie.Router.error(error_code::Int, error_message::String, ::Type{MIME"text/html"}; error_info::String = "") :: HTTP.Response

Returns an error response as an HTML doc.
"""
function Genie.Router.error(error_code::Int, error_message::String, ::Type{MIME"text/html"}; error_info::String = "") :: HTTP.Response
  serve_error_file(error_code, error_message, error_info = error_info)
end


"""
    serve_error_file(error_code::Int, error_message::String = "", params::Dict{Symbol,Any} = Dict{Symbol,Any}()) :: Response

Serves the error file correspoding to `error_code` and current environment.
"""
function serve_error_file(error_code::Int, error_message::String = ""; error_info::String = "") :: HTTP.Response
  page_code = error_code in [404, 500] ? "$error_code" : "xxx"

  try
    error_page_file = isfile(joinpath(Genie.config.server_document_root, "error-$page_code.html")) ?
                        joinpath(Genie.config.server_document_root, "error-$page_code.html") :
                          joinpath(@__DIR__, "..", "..", "files", "static", "error-$page_code.html")

    error_page =  open(error_page_file) do f
                    read(f, String)
                  end

    if error_code == 500
      error_page = replace(error_page, "<error_description/>"=>split(error_message, "\n")[1])

      error_message = if Genie.Configuration.isdev()
                      """$("#" ^ 25) ERROR STACKTRACE $("#" ^ 25)\n$error_message                                     $("\n" ^ 3)""" *
                      """$("#" ^ 25)  REQUEST PARAMS  $("#" ^ 25)\n$(Millboard.table(Genie.Router.params()))                        $("\n" ^ 3)""" *
                      """$("#" ^ 25)     ROUTES       $("#" ^ 25)\n$(Millboard.table(Genie.Router.named_routes() |> Dict))  $("\n" ^ 3)""" *
                      """$("#" ^ 25)    JULIA ENV     $("#" ^ 25)\n$ENV                                               $("\n" ^ 1)"""
      else
        ""
      end

      error_page = replace(error_page, "<error_message/>"=>escapeHTML(error_message))

    elseif error_code == 404
      error_page = replace(error_page, "<error_message/>"=>error_message)

    else
      error_page = replace(replace(error_page, "<error_message/>"=>error_message), "<error_info/>"=>error_info)
    end

    HTTP.Response(error_code, ["Content-Type"=>"text/html"], body = error_page)
  catch ex
    @error ex
    HTTP.Response(error_code, ["Content-Type"=>"text/html"], body = "Error $page_code: $error_message")
  end
end


### === ###


"""
    @yield

Outputs the rendering of the view within the template.
"""
macro yield()
  quote
    view!()
  end
end
macro yield(value)
  :(view!($value))
end


function view!()
  try
    task_local_storage(:__yield)
  catch
    task_local_storage(:__yield, "")
  end
end

function view!(value)
  task_local_storage(:__yield, value)
end


function el(; vars...)
  OrderedCollections.OrderedDict(vars)
end


register_elements()

end
