export html, head, body, title, style, address, article, aside, footer, header, h1, h2, h3, h4, h5, h6, hgroup, nav, section, dd, div, d, dl, dt, figcaption, figure, li, ol, p, pre, ul, span, a, abbr, b, bdi, bdo, cite, code, data, dfn, em, i, kbd, mark, q, rp, rt, rtc, ruby, s, samp, small, strong, sub, sup, time, u, var, wrb, audio, void, embed, object, canvas, noscript, script, del, ins, caption, col, colgroup, table, tbody, td, tfoot, th, thead, tr, button, datalist, fieldset, label, legend, meter, output, progress, select, option, textarea, details, dialog, menu, menuitem, summary, slot, template, blockquote, center, iframe, form, base, link, meta, hr, br, area, img, track, param, source, input, animate, circle, animateMotion, animateTransform, clipPath, defs, desc, discard, ellipse, feComponentTransfer, feComposite, feDiffuseLighting, feBlend, feColorMatrix, feConvolveMatrix, feDisplacementMap, feDistantLight, feDropShadow, feFlood, feFuncA, feFuncB, feFuncG, feFuncR, feGaussianBlur, feImage, feMerge, feMergeNode, feMorphology, feOffset, fePointLight, feSpecularLighting, feSpotLight, feTile, feTurbulence, foreignObject, g, hatch, hatchpath, image, line, linearGradient, marker, mask, metadata, mpath, path, pattern, polygon, polyline, radialGradient, rect, set, stop, svg, switch, symbol, text, textPath, tspan, use, view

  function html(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "html", [args...], Pair{Symbol,Any}[attrs...])
  end
  function html(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "html", [args...], Pair{Symbol,Any}[attrs...])
  end
  function html(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "html", [args...], Pair{Symbol,Any}[attrs...])
  end
  function html(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "html", [args...], Pair{Symbol,Any}[attrs...])
  end

  function head(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "head", [args...], Pair{Symbol,Any}[attrs...])
  end
  function head(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "head", [args...], Pair{Symbol,Any}[attrs...])
  end
  function head(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "head", [args...], Pair{Symbol,Any}[attrs...])
  end
  function head(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "head", [args...], Pair{Symbol,Any}[attrs...])
  end

  function body(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "body", [args...], Pair{Symbol,Any}[attrs...])
  end
  function body(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "body", [args...], Pair{Symbol,Any}[attrs...])
  end
  function body(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "body", [args...], Pair{Symbol,Any}[attrs...])
  end
  function body(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "body", [args...], Pair{Symbol,Any}[attrs...])
  end

  function title(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "title", [args...], Pair{Symbol,Any}[attrs...])
  end
  function title(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "title", [args...], Pair{Symbol,Any}[attrs...])
  end
  function title(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "title", [args...], Pair{Symbol,Any}[attrs...])
  end
  function title(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "title", [args...], Pair{Symbol,Any}[attrs...])
  end

  function style(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "style", [args...], Pair{Symbol,Any}[attrs...])
  end
  function style(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "style", [args...], Pair{Symbol,Any}[attrs...])
  end
  function style(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "style", [args...], Pair{Symbol,Any}[attrs...])
  end
  function style(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "style", [args...], Pair{Symbol,Any}[attrs...])
  end

  function address(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "address", [args...], Pair{Symbol,Any}[attrs...])
  end
  function address(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "address", [args...], Pair{Symbol,Any}[attrs...])
  end
  function address(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "address", [args...], Pair{Symbol,Any}[attrs...])
  end
  function address(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "address", [args...], Pair{Symbol,Any}[attrs...])
  end

  function article(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "article", [args...], Pair{Symbol,Any}[attrs...])
  end
  function article(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "article", [args...], Pair{Symbol,Any}[attrs...])
  end
  function article(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "article", [args...], Pair{Symbol,Any}[attrs...])
  end
  function article(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "article", [args...], Pair{Symbol,Any}[attrs...])
  end

  function aside(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "aside", [args...], Pair{Symbol,Any}[attrs...])
  end
  function aside(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "aside", [args...], Pair{Symbol,Any}[attrs...])
  end
  function aside(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "aside", [args...], Pair{Symbol,Any}[attrs...])
  end
  function aside(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "aside", [args...], Pair{Symbol,Any}[attrs...])
  end

  function footer(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "footer", [args...], Pair{Symbol,Any}[attrs...])
  end
  function footer(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "footer", [args...], Pair{Symbol,Any}[attrs...])
  end
  function footer(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "footer", [args...], Pair{Symbol,Any}[attrs...])
  end
  function footer(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "footer", [args...], Pair{Symbol,Any}[attrs...])
  end

  function header(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "header", [args...], Pair{Symbol,Any}[attrs...])
  end
  function header(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "header", [args...], Pair{Symbol,Any}[attrs...])
  end
  function header(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "header", [args...], Pair{Symbol,Any}[attrs...])
  end
  function header(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "header", [args...], Pair{Symbol,Any}[attrs...])
  end

  function h1(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "h1", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h1(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "h1", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h1(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "h1", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h1(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "h1", [args...], Pair{Symbol,Any}[attrs...])
  end

  function h2(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "h2", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h2(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "h2", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h2(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "h2", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h2(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "h2", [args...], Pair{Symbol,Any}[attrs...])
  end

  function h3(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "h3", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h3(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "h3", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h3(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "h3", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h3(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "h3", [args...], Pair{Symbol,Any}[attrs...])
  end

  function h4(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "h4", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h4(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "h4", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h4(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "h4", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h4(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "h4", [args...], Pair{Symbol,Any}[attrs...])
  end

  function h5(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "h5", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h5(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "h5", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h5(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "h5", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h5(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "h5", [args...], Pair{Symbol,Any}[attrs...])
  end

  function h6(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "h6", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h6(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "h6", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h6(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "h6", [args...], Pair{Symbol,Any}[attrs...])
  end
  function h6(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "h6", [args...], Pair{Symbol,Any}[attrs...])
  end

  function hgroup(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "hgroup", [args...], Pair{Symbol,Any}[attrs...])
  end
  function hgroup(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "hgroup", [args...], Pair{Symbol,Any}[attrs...])
  end
  function hgroup(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "hgroup", [args...], Pair{Symbol,Any}[attrs...])
  end
  function hgroup(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "hgroup", [args...], Pair{Symbol,Any}[attrs...])
  end

  function nav(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "nav", [args...], Pair{Symbol,Any}[attrs...])
  end
  function nav(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "nav", [args...], Pair{Symbol,Any}[attrs...])
  end
  function nav(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "nav", [args...], Pair{Symbol,Any}[attrs...])
  end
  function nav(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "nav", [args...], Pair{Symbol,Any}[attrs...])
  end

  function section(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "section", [args...], Pair{Symbol,Any}[attrs...])
  end
  function section(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "section", [args...], Pair{Symbol,Any}[attrs...])
  end
  function section(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "section", [args...], Pair{Symbol,Any}[attrs...])
  end
  function section(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "section", [args...], Pair{Symbol,Any}[attrs...])
  end

  function dd(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "dd", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dd(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "dd", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dd(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "dd", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dd(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "dd", [args...], Pair{Symbol,Any}[attrs...])
  end

  function div(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "div", [args...], Pair{Symbol,Any}[attrs...])
  end
  function div(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "div", [args...], Pair{Symbol,Any}[attrs...])
  end
  function div(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "div", [args...], Pair{Symbol,Any}[attrs...])
  end
  function div(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "div", [args...], Pair{Symbol,Any}[attrs...])
  end

  function d(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "d", [args...], Pair{Symbol,Any}[attrs...])
  end
  function d(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "d", [args...], Pair{Symbol,Any}[attrs...])
  end
  function d(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "d", [args...], Pair{Symbol,Any}[attrs...])
  end
  function d(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "d", [args...], Pair{Symbol,Any}[attrs...])
  end

  function dl(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "dl", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dl(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "dl", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dl(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "dl", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dl(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "dl", [args...], Pair{Symbol,Any}[attrs...])
  end

  function dt(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "dt", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dt(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "dt", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dt(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "dt", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dt(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "dt", [args...], Pair{Symbol,Any}[attrs...])
  end

  function figcaption(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "figcaption", [args...], Pair{Symbol,Any}[attrs...])
  end
  function figcaption(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "figcaption", [args...], Pair{Symbol,Any}[attrs...])
  end
  function figcaption(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "figcaption", [args...], Pair{Symbol,Any}[attrs...])
  end
  function figcaption(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "figcaption", [args...], Pair{Symbol,Any}[attrs...])
  end

  function figure(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "figure", [args...], Pair{Symbol,Any}[attrs...])
  end
  function figure(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "figure", [args...], Pair{Symbol,Any}[attrs...])
  end
  function figure(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "figure", [args...], Pair{Symbol,Any}[attrs...])
  end
  function figure(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "figure", [args...], Pair{Symbol,Any}[attrs...])
  end

  function li(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "li", [args...], Pair{Symbol,Any}[attrs...])
  end
  function li(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "li", [args...], Pair{Symbol,Any}[attrs...])
  end
  function li(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "li", [args...], Pair{Symbol,Any}[attrs...])
  end
  function li(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "li", [args...], Pair{Symbol,Any}[attrs...])
  end

  function main(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "main", [args...], Pair{Symbol,Any}[attrs...])
  end
  function main(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "main", [args...], Pair{Symbol,Any}[attrs...])
  end
  function main(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "main", [args...], Pair{Symbol,Any}[attrs...])
  end
  function main(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "main", [args...], Pair{Symbol,Any}[attrs...])
  end

  function ol(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "ol", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ol(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "ol", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ol(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "ol", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ol(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "ol", [args...], Pair{Symbol,Any}[attrs...])
  end

  function p(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "p", [args...], Pair{Symbol,Any}[attrs...])
  end
  function p(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "p", [args...], Pair{Symbol,Any}[attrs...])
  end
  function p(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "p", [args...], Pair{Symbol,Any}[attrs...])
  end
  function p(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "p", [args...], Pair{Symbol,Any}[attrs...])
  end

  function pre(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "pre", [args...], Pair{Symbol,Any}[attrs...])
  end
  function pre(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "pre", [args...], Pair{Symbol,Any}[attrs...])
  end
  function pre(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "pre", [args...], Pair{Symbol,Any}[attrs...])
  end
  function pre(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "pre", [args...], Pair{Symbol,Any}[attrs...])
  end

  function ul(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "ul", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ul(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "ul", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ul(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "ul", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ul(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "ul", [args...], Pair{Symbol,Any}[attrs...])
  end

  function span(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "span", [args...], Pair{Symbol,Any}[attrs...])
  end
  function span(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "span", [args...], Pair{Symbol,Any}[attrs...])
  end
  function span(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "span", [args...], Pair{Symbol,Any}[attrs...])
  end
  function span(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "span", [args...], Pair{Symbol,Any}[attrs...])
  end

  function a(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "a", [args...], Pair{Symbol,Any}[attrs...])
  end
  function a(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "a", [args...], Pair{Symbol,Any}[attrs...])
  end
  function a(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "a", [args...], Pair{Symbol,Any}[attrs...])
  end
  function a(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "a", [args...], Pair{Symbol,Any}[attrs...])
  end

  function abbr(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "abbr", [args...], Pair{Symbol,Any}[attrs...])
  end
  function abbr(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "abbr", [args...], Pair{Symbol,Any}[attrs...])
  end
  function abbr(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "abbr", [args...], Pair{Symbol,Any}[attrs...])
  end
  function abbr(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "abbr", [args...], Pair{Symbol,Any}[attrs...])
  end

  function b(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "b", [args...], Pair{Symbol,Any}[attrs...])
  end
  function b(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "b", [args...], Pair{Symbol,Any}[attrs...])
  end
  function b(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "b", [args...], Pair{Symbol,Any}[attrs...])
  end
  function b(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "b", [args...], Pair{Symbol,Any}[attrs...])
  end

  function bdi(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "bdi", [args...], Pair{Symbol,Any}[attrs...])
  end
  function bdi(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "bdi", [args...], Pair{Symbol,Any}[attrs...])
  end
  function bdi(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "bdi", [args...], Pair{Symbol,Any}[attrs...])
  end
  function bdi(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "bdi", [args...], Pair{Symbol,Any}[attrs...])
  end

  function bdo(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "bdo", [args...], Pair{Symbol,Any}[attrs...])
  end
  function bdo(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "bdo", [args...], Pair{Symbol,Any}[attrs...])
  end
  function bdo(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "bdo", [args...], Pair{Symbol,Any}[attrs...])
  end
  function bdo(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "bdo", [args...], Pair{Symbol,Any}[attrs...])
  end

  function cite(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "cite", [args...], Pair{Symbol,Any}[attrs...])
  end
  function cite(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "cite", [args...], Pair{Symbol,Any}[attrs...])
  end
  function cite(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "cite", [args...], Pair{Symbol,Any}[attrs...])
  end
  function cite(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "cite", [args...], Pair{Symbol,Any}[attrs...])
  end

  function code(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "code", [args...], Pair{Symbol,Any}[attrs...])
  end
  function code(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "code", [args...], Pair{Symbol,Any}[attrs...])
  end
  function code(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "code", [args...], Pair{Symbol,Any}[attrs...])
  end
  function code(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "code", [args...], Pair{Symbol,Any}[attrs...])
  end

  function data(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "data", [args...], Pair{Symbol,Any}[attrs...])
  end
  function data(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "data", [args...], Pair{Symbol,Any}[attrs...])
  end
  function data(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "data", [args...], Pair{Symbol,Any}[attrs...])
  end
  function data(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "data", [args...], Pair{Symbol,Any}[attrs...])
  end

  function dfn(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "dfn", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dfn(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "dfn", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dfn(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "dfn", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dfn(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "dfn", [args...], Pair{Symbol,Any}[attrs...])
  end

  function em(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "em", [args...], Pair{Symbol,Any}[attrs...])
  end
  function em(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "em", [args...], Pair{Symbol,Any}[attrs...])
  end
  function em(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "em", [args...], Pair{Symbol,Any}[attrs...])
  end
  function em(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "em", [args...], Pair{Symbol,Any}[attrs...])
  end

  function i(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "i", [args...], Pair{Symbol,Any}[attrs...])
  end
  function i(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "i", [args...], Pair{Symbol,Any}[attrs...])
  end
  function i(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "i", [args...], Pair{Symbol,Any}[attrs...])
  end
  function i(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "i", [args...], Pair{Symbol,Any}[attrs...])
  end

  function kbd(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "kbd", [args...], Pair{Symbol,Any}[attrs...])
  end
  function kbd(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "kbd", [args...], Pair{Symbol,Any}[attrs...])
  end
  function kbd(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "kbd", [args...], Pair{Symbol,Any}[attrs...])
  end
  function kbd(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "kbd", [args...], Pair{Symbol,Any}[attrs...])
  end

  function mark(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "mark", [args...], Pair{Symbol,Any}[attrs...])
  end
  function mark(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "mark", [args...], Pair{Symbol,Any}[attrs...])
  end
  function mark(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "mark", [args...], Pair{Symbol,Any}[attrs...])
  end
  function mark(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "mark", [args...], Pair{Symbol,Any}[attrs...])
  end

  function q(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "q", [args...], Pair{Symbol,Any}[attrs...])
  end
  function q(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "q", [args...], Pair{Symbol,Any}[attrs...])
  end
  function q(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "q", [args...], Pair{Symbol,Any}[attrs...])
  end
  function q(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "q", [args...], Pair{Symbol,Any}[attrs...])
  end

  function rp(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "rp", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rp(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "rp", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rp(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "rp", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rp(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "rp", [args...], Pair{Symbol,Any}[attrs...])
  end

  function rt(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "rt", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rt(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "rt", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rt(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "rt", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rt(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "rt", [args...], Pair{Symbol,Any}[attrs...])
  end

  function rtc(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "rtc", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rtc(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "rtc", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rtc(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "rtc", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rtc(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "rtc", [args...], Pair{Symbol,Any}[attrs...])
  end

  function ruby(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "ruby", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ruby(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "ruby", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ruby(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "ruby", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ruby(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "ruby", [args...], Pair{Symbol,Any}[attrs...])
  end

  function s(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "s", [args...], Pair{Symbol,Any}[attrs...])
  end
  function s(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "s", [args...], Pair{Symbol,Any}[attrs...])
  end
  function s(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "s", [args...], Pair{Symbol,Any}[attrs...])
  end
  function s(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "s", [args...], Pair{Symbol,Any}[attrs...])
  end

  function samp(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "samp", [args...], Pair{Symbol,Any}[attrs...])
  end
  function samp(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "samp", [args...], Pair{Symbol,Any}[attrs...])
  end
  function samp(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "samp", [args...], Pair{Symbol,Any}[attrs...])
  end
  function samp(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "samp", [args...], Pair{Symbol,Any}[attrs...])
  end

  function small(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "small", [args...], Pair{Symbol,Any}[attrs...])
  end
  function small(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "small", [args...], Pair{Symbol,Any}[attrs...])
  end
  function small(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "small", [args...], Pair{Symbol,Any}[attrs...])
  end
  function small(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "small", [args...], Pair{Symbol,Any}[attrs...])
  end

  function strong(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "strong", [args...], Pair{Symbol,Any}[attrs...])
  end
  function strong(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "strong", [args...], Pair{Symbol,Any}[attrs...])
  end
  function strong(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "strong", [args...], Pair{Symbol,Any}[attrs...])
  end
  function strong(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "strong", [args...], Pair{Symbol,Any}[attrs...])
  end

  function sub(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "sub", [args...], Pair{Symbol,Any}[attrs...])
  end
  function sub(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "sub", [args...], Pair{Symbol,Any}[attrs...])
  end
  function sub(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "sub", [args...], Pair{Symbol,Any}[attrs...])
  end
  function sub(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "sub", [args...], Pair{Symbol,Any}[attrs...])
  end

  function sup(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "sup", [args...], Pair{Symbol,Any}[attrs...])
  end
  function sup(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "sup", [args...], Pair{Symbol,Any}[attrs...])
  end
  function sup(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "sup", [args...], Pair{Symbol,Any}[attrs...])
  end
  function sup(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "sup", [args...], Pair{Symbol,Any}[attrs...])
  end

  function time(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "time", [args...], Pair{Symbol,Any}[attrs...])
  end
  function time(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "time", [args...], Pair{Symbol,Any}[attrs...])
  end
  function time(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "time", [args...], Pair{Symbol,Any}[attrs...])
  end
  function time(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "time", [args...], Pair{Symbol,Any}[attrs...])
  end

  function u(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "u", [args...], Pair{Symbol,Any}[attrs...])
  end
  function u(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "u", [args...], Pair{Symbol,Any}[attrs...])
  end
  function u(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "u", [args...], Pair{Symbol,Any}[attrs...])
  end
  function u(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "u", [args...], Pair{Symbol,Any}[attrs...])
  end

  function var(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "var", [args...], Pair{Symbol,Any}[attrs...])
  end
  function var(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "var", [args...], Pair{Symbol,Any}[attrs...])
  end
  function var(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "var", [args...], Pair{Symbol,Any}[attrs...])
  end
  function var(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "var", [args...], Pair{Symbol,Any}[attrs...])
  end

  function wrb(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "wrb", [args...], Pair{Symbol,Any}[attrs...])
  end
  function wrb(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "wrb", [args...], Pair{Symbol,Any}[attrs...])
  end
  function wrb(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "wrb", [args...], Pair{Symbol,Any}[attrs...])
  end
  function wrb(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "wrb", [args...], Pair{Symbol,Any}[attrs...])
  end

  function audio(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "audio", [args...], Pair{Symbol,Any}[attrs...])
  end
  function audio(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "audio", [args...], Pair{Symbol,Any}[attrs...])
  end
  function audio(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "audio", [args...], Pair{Symbol,Any}[attrs...])
  end
  function audio(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "audio", [args...], Pair{Symbol,Any}[attrs...])
  end

  function void(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "void", [args...], Pair{Symbol,Any}[attrs...])
  end
  function void(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "void", [args...], Pair{Symbol,Any}[attrs...])
  end
  function void(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "void", [args...], Pair{Symbol,Any}[attrs...])
  end
  function void(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "void", [args...], Pair{Symbol,Any}[attrs...])
  end

  function embed(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "embed", [args...], Pair{Symbol,Any}[attrs...])
  end
  function embed(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "embed", [args...], Pair{Symbol,Any}[attrs...])
  end
  function embed(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "embed", [args...], Pair{Symbol,Any}[attrs...])
  end
  function embed(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "embed", [args...], Pair{Symbol,Any}[attrs...])
  end

  function object(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "object", [args...], Pair{Symbol,Any}[attrs...])
  end
  function object(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "object", [args...], Pair{Symbol,Any}[attrs...])
  end
  function object(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "object", [args...], Pair{Symbol,Any}[attrs...])
  end
  function object(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "object", [args...], Pair{Symbol,Any}[attrs...])
  end

  function canvas(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "canvas", [args...], Pair{Symbol,Any}[attrs...])
  end
  function canvas(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "canvas", [args...], Pair{Symbol,Any}[attrs...])
  end
  function canvas(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "canvas", [args...], Pair{Symbol,Any}[attrs...])
  end
  function canvas(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "canvas", [args...], Pair{Symbol,Any}[attrs...])
  end

  function noscript(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "noscript", [args...], Pair{Symbol,Any}[attrs...])
  end
  function noscript(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "noscript", [args...], Pair{Symbol,Any}[attrs...])
  end
  function noscript(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "noscript", [args...], Pair{Symbol,Any}[attrs...])
  end
  function noscript(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "noscript", [args...], Pair{Symbol,Any}[attrs...])
  end

  function script(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "script", [args...], Pair{Symbol,Any}[attrs...])
  end
  function script(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "script", [args...], Pair{Symbol,Any}[attrs...])
  end
  function script(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "script", [args...], Pair{Symbol,Any}[attrs...])
  end
  function script(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "script", [args...], Pair{Symbol,Any}[attrs...])
  end

  function del(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "del", [args...], Pair{Symbol,Any}[attrs...])
  end
  function del(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "del", [args...], Pair{Symbol,Any}[attrs...])
  end
  function del(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "del", [args...], Pair{Symbol,Any}[attrs...])
  end
  function del(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "del", [args...], Pair{Symbol,Any}[attrs...])
  end

  function ins(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "ins", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ins(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "ins", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ins(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "ins", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ins(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "ins", [args...], Pair{Symbol,Any}[attrs...])
  end

  function caption(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "caption", [args...], Pair{Symbol,Any}[attrs...])
  end
  function caption(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "caption", [args...], Pair{Symbol,Any}[attrs...])
  end
  function caption(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "caption", [args...], Pair{Symbol,Any}[attrs...])
  end
  function caption(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "caption", [args...], Pair{Symbol,Any}[attrs...])
  end

  function col(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "col", [args...], Pair{Symbol,Any}[attrs...])
  end
  function col(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "col", [args...], Pair{Symbol,Any}[attrs...])
  end
  function col(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "col", [args...], Pair{Symbol,Any}[attrs...])
  end
  function col(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "col", [args...], Pair{Symbol,Any}[attrs...])
  end

  function colgroup(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "colgroup", [args...], Pair{Symbol,Any}[attrs...])
  end
  function colgroup(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "colgroup", [args...], Pair{Symbol,Any}[attrs...])
  end
  function colgroup(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "colgroup", [args...], Pair{Symbol,Any}[attrs...])
  end
  function colgroup(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "colgroup", [args...], Pair{Symbol,Any}[attrs...])
  end

  function table(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "table", [args...], Pair{Symbol,Any}[attrs...])
  end
  function table(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "table", [args...], Pair{Symbol,Any}[attrs...])
  end
  function table(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "table", [args...], Pair{Symbol,Any}[attrs...])
  end
  function table(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "table", [args...], Pair{Symbol,Any}[attrs...])
  end

  function tbody(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "tbody", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tbody(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "tbody", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tbody(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "tbody", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tbody(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "tbody", [args...], Pair{Symbol,Any}[attrs...])
  end

  function td(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "td", [args...], Pair{Symbol,Any}[attrs...])
  end
  function td(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "td", [args...], Pair{Symbol,Any}[attrs...])
  end
  function td(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "td", [args...], Pair{Symbol,Any}[attrs...])
  end
  function td(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "td", [args...], Pair{Symbol,Any}[attrs...])
  end

  function tfoot(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "tfoot", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tfoot(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "tfoot", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tfoot(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "tfoot", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tfoot(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "tfoot", [args...], Pair{Symbol,Any}[attrs...])
  end

  function th(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "th", [args...], Pair{Symbol,Any}[attrs...])
  end
  function th(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "th", [args...], Pair{Symbol,Any}[attrs...])
  end
  function th(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "th", [args...], Pair{Symbol,Any}[attrs...])
  end
  function th(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "th", [args...], Pair{Symbol,Any}[attrs...])
  end

  function thead(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "thead", [args...], Pair{Symbol,Any}[attrs...])
  end
  function thead(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "thead", [args...], Pair{Symbol,Any}[attrs...])
  end
  function thead(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "thead", [args...], Pair{Symbol,Any}[attrs...])
  end
  function thead(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "thead", [args...], Pair{Symbol,Any}[attrs...])
  end

  function tr(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "tr", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tr(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "tr", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tr(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "tr", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tr(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "tr", [args...], Pair{Symbol,Any}[attrs...])
  end

  function button(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "button", [args...], Pair{Symbol,Any}[attrs...])
  end
  function button(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "button", [args...], Pair{Symbol,Any}[attrs...])
  end
  function button(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "button", [args...], Pair{Symbol,Any}[attrs...])
  end
  function button(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "button", [args...], Pair{Symbol,Any}[attrs...])
  end

  function datalist(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "datalist", [args...], Pair{Symbol,Any}[attrs...])
  end
  function datalist(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "datalist", [args...], Pair{Symbol,Any}[attrs...])
  end
  function datalist(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "datalist", [args...], Pair{Symbol,Any}[attrs...])
  end
  function datalist(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "datalist", [args...], Pair{Symbol,Any}[attrs...])
  end

  function fieldset(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "fieldset", [args...], Pair{Symbol,Any}[attrs...])
  end
  function fieldset(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "fieldset", [args...], Pair{Symbol,Any}[attrs...])
  end
  function fieldset(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "fieldset", [args...], Pair{Symbol,Any}[attrs...])
  end
  function fieldset(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "fieldset", [args...], Pair{Symbol,Any}[attrs...])
  end

  function label(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "label", [args...], Pair{Symbol,Any}[attrs...])
  end
  function label(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "label", [args...], Pair{Symbol,Any}[attrs...])
  end
  function label(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "label", [args...], Pair{Symbol,Any}[attrs...])
  end
  function label(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "label", [args...], Pair{Symbol,Any}[attrs...])
  end

  function legend(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "legend", [args...], Pair{Symbol,Any}[attrs...])
  end
  function legend(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "legend", [args...], Pair{Symbol,Any}[attrs...])
  end
  function legend(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "legend", [args...], Pair{Symbol,Any}[attrs...])
  end
  function legend(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "legend", [args...], Pair{Symbol,Any}[attrs...])
  end

  function meter(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "meter", [args...], Pair{Symbol,Any}[attrs...])
  end
  function meter(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "meter", [args...], Pair{Symbol,Any}[attrs...])
  end
  function meter(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "meter", [args...], Pair{Symbol,Any}[attrs...])
  end
  function meter(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "meter", [args...], Pair{Symbol,Any}[attrs...])
  end

  function output(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "output", [args...], Pair{Symbol,Any}[attrs...])
  end
  function output(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "output", [args...], Pair{Symbol,Any}[attrs...])
  end
  function output(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "output", [args...], Pair{Symbol,Any}[attrs...])
  end
  function output(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "output", [args...], Pair{Symbol,Any}[attrs...])
  end

  function progress(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "progress", [args...], Pair{Symbol,Any}[attrs...])
  end
  function progress(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "progress", [args...], Pair{Symbol,Any}[attrs...])
  end
  function progress(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "progress", [args...], Pair{Symbol,Any}[attrs...])
  end
  function progress(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "progress", [args...], Pair{Symbol,Any}[attrs...])
  end

  function select(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "select", [args...], Pair{Symbol,Any}[attrs...])
  end
  function select(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "select", [args...], Pair{Symbol,Any}[attrs...])
  end
  function select(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "select", [args...], Pair{Symbol,Any}[attrs...])
  end
  function select(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "select", [args...], Pair{Symbol,Any}[attrs...])
  end

  function option(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "option", [args...], Pair{Symbol,Any}[attrs...])
  end
  function option(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "option", [args...], Pair{Symbol,Any}[attrs...])
  end
  function option(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "option", [args...], Pair{Symbol,Any}[attrs...])
  end
  function option(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "option", [args...], Pair{Symbol,Any}[attrs...])
  end

  function textarea(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "textarea", [args...], Pair{Symbol,Any}[attrs...])
  end
  function textarea(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "textarea", [args...], Pair{Symbol,Any}[attrs...])
  end
  function textarea(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "textarea", [args...], Pair{Symbol,Any}[attrs...])
  end
  function textarea(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "textarea", [args...], Pair{Symbol,Any}[attrs...])
  end

  function details(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "details", [args...], Pair{Symbol,Any}[attrs...])
  end
  function details(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "details", [args...], Pair{Symbol,Any}[attrs...])
  end
  function details(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "details", [args...], Pair{Symbol,Any}[attrs...])
  end
  function details(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "details", [args...], Pair{Symbol,Any}[attrs...])
  end

  function dialog(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "dialog", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dialog(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "dialog", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dialog(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "dialog", [args...], Pair{Symbol,Any}[attrs...])
  end
  function dialog(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "dialog", [args...], Pair{Symbol,Any}[attrs...])
  end

  function menu(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "menu", [args...], Pair{Symbol,Any}[attrs...])
  end
  function menu(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "menu", [args...], Pair{Symbol,Any}[attrs...])
  end
  function menu(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "menu", [args...], Pair{Symbol,Any}[attrs...])
  end
  function menu(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "menu", [args...], Pair{Symbol,Any}[attrs...])
  end

  function menuitem(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "menuitem", [args...], Pair{Symbol,Any}[attrs...])
  end
  function menuitem(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "menuitem", [args...], Pair{Symbol,Any}[attrs...])
  end
  function menuitem(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "menuitem", [args...], Pair{Symbol,Any}[attrs...])
  end
  function menuitem(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "menuitem", [args...], Pair{Symbol,Any}[attrs...])
  end

  function summary(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "summary", [args...], Pair{Symbol,Any}[attrs...])
  end
  function summary(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "summary", [args...], Pair{Symbol,Any}[attrs...])
  end
  function summary(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "summary", [args...], Pair{Symbol,Any}[attrs...])
  end
  function summary(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "summary", [args...], Pair{Symbol,Any}[attrs...])
  end

  function slot(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "slot", [args...], Pair{Symbol,Any}[attrs...])
  end
  function slot(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "slot", [args...], Pair{Symbol,Any}[attrs...])
  end
  function slot(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "slot", [args...], Pair{Symbol,Any}[attrs...])
  end
  function slot(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "slot", [args...], Pair{Symbol,Any}[attrs...])
  end

  function template(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "template", [args...], Pair{Symbol,Any}[attrs...])
  end
  function template(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "template", [args...], Pair{Symbol,Any}[attrs...])
  end
  function template(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "template", [args...], Pair{Symbol,Any}[attrs...])
  end
  function template(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "template", [args...], Pair{Symbol,Any}[attrs...])
  end

  function blockquote(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "blockquote", [args...], Pair{Symbol,Any}[attrs...])
  end
  function blockquote(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "blockquote", [args...], Pair{Symbol,Any}[attrs...])
  end
  function blockquote(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "blockquote", [args...], Pair{Symbol,Any}[attrs...])
  end
  function blockquote(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "blockquote", [args...], Pair{Symbol,Any}[attrs...])
  end

  function center(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "center", [args...], Pair{Symbol,Any}[attrs...])
  end
  function center(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "center", [args...], Pair{Symbol,Any}[attrs...])
  end
  function center(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "center", [args...], Pair{Symbol,Any}[attrs...])
  end
  function center(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "center", [args...], Pair{Symbol,Any}[attrs...])
  end

  function iframe(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "iframe", [args...], Pair{Symbol,Any}[attrs...])
  end
  function iframe(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "iframe", [args...], Pair{Symbol,Any}[attrs...])
  end
  function iframe(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "iframe", [args...], Pair{Symbol,Any}[attrs...])
  end
  function iframe(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "iframe", [args...], Pair{Symbol,Any}[attrs...])
  end

  function form(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "form", [args...], Pair{Symbol,Any}[attrs...])
  end
  function form(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "form", [args...], Pair{Symbol,Any}[attrs...])
  end
  function form(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "form", [args...], Pair{Symbol,Any}[attrs...])
  end
  function form(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "form", [args...], Pair{Symbol,Any}[attrs...])
  end

  function base(args...; attrs...) :: ParsedHTMLString
    void_element("base", [args...], Pair{Symbol,Any}[attrs...])
  end

  function link(args...; attrs...) :: ParsedHTMLString
    void_element("link", [args...], Pair{Symbol,Any}[attrs...])
  end

  function meta(args...; attrs...) :: ParsedHTMLString
    void_element("meta", [args...], Pair{Symbol,Any}[attrs...])
  end

  function hr(args...; attrs...) :: ParsedHTMLString
    void_element("hr", [args...], Pair{Symbol,Any}[attrs...])
  end

  function br(args...; attrs...) :: ParsedHTMLString
    void_element("br", [args...], Pair{Symbol,Any}[attrs...])
  end

  function area(args...; attrs...) :: ParsedHTMLString
    void_element("area", [args...], Pair{Symbol,Any}[attrs...])
  end

  function img(args...; attrs...) :: ParsedHTMLString
    void_element("img", [args...], Pair{Symbol,Any}[attrs...])
  end

  function track(args...; attrs...) :: ParsedHTMLString
    void_element("track", [args...], Pair{Symbol,Any}[attrs...])
  end

  function param(args...; attrs...) :: ParsedHTMLString
    void_element("param", [args...], Pair{Symbol,Any}[attrs...])
  end

  function source(args...; attrs...) :: ParsedHTMLString
    void_element("source", [args...], Pair{Symbol,Any}[attrs...])
  end

  function input(args...; attrs...) :: ParsedHTMLString
    void_element("input", [args...], Pair{Symbol,Any}[attrs...])
  end

  function animate(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "animate", [args...], Pair{Symbol,Any}[attrs...])
  end
  function animate(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "animate", [args...], Pair{Symbol,Any}[attrs...])
  end
  function animate(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "animate", [args...], Pair{Symbol,Any}[attrs...])
  end
  function animate(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "animate", [args...], Pair{Symbol,Any}[attrs...])
  end

  function circle(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "circle", [args...], Pair{Symbol,Any}[attrs...])
  end
  function circle(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "circle", [args...], Pair{Symbol,Any}[attrs...])
  end
  function circle(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "circle", [args...], Pair{Symbol,Any}[attrs...])
  end
  function circle(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "circle", [args...], Pair{Symbol,Any}[attrs...])
  end

  function animateMotion(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "animateMotion", [args...], Pair{Symbol,Any}[attrs...])
  end
  function animateMotion(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "animateMotion", [args...], Pair{Symbol,Any}[attrs...])
  end
  function animateMotion(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "animateMotion", [args...], Pair{Symbol,Any}[attrs...])
  end
  function animateMotion(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "animateMotion", [args...], Pair{Symbol,Any}[attrs...])
  end

  function animateTransform(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "animateTransform", [args...], Pair{Symbol,Any}[attrs...])
  end
  function animateTransform(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "animateTransform", [args...], Pair{Symbol,Any}[attrs...])
  end
  function animateTransform(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "animateTransform", [args...], Pair{Symbol,Any}[attrs...])
  end
  function animateTransform(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "animateTransform", [args...], Pair{Symbol,Any}[attrs...])
  end

  function clipPath(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "clipPath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function clipPath(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "clipPath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function clipPath(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "clipPath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function clipPath(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "clipPath", [args...], Pair{Symbol,Any}[attrs...])
  end

  function defs(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "defs", [args...], Pair{Symbol,Any}[attrs...])
  end
  function defs(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "defs", [args...], Pair{Symbol,Any}[attrs...])
  end
  function defs(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "defs", [args...], Pair{Symbol,Any}[attrs...])
  end
  function defs(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "defs", [args...], Pair{Symbol,Any}[attrs...])
  end

  function desc(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "desc", [args...], Pair{Symbol,Any}[attrs...])
  end
  function desc(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "desc", [args...], Pair{Symbol,Any}[attrs...])
  end
  function desc(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "desc", [args...], Pair{Symbol,Any}[attrs...])
  end
  function desc(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "desc", [args...], Pair{Symbol,Any}[attrs...])
  end

  function discard(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "discard", [args...], Pair{Symbol,Any}[attrs...])
  end
  function discard(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "discard", [args...], Pair{Symbol,Any}[attrs...])
  end
  function discard(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "discard", [args...], Pair{Symbol,Any}[attrs...])
  end
  function discard(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "discard", [args...], Pair{Symbol,Any}[attrs...])
  end

  function ellipse(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "ellipse", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ellipse(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "ellipse", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ellipse(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "ellipse", [args...], Pair{Symbol,Any}[attrs...])
  end
  function ellipse(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "ellipse", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feComponentTransfer(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feComponentTransfer", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feComponentTransfer(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feComponentTransfer", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feComponentTransfer(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feComponentTransfer", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feComponentTransfer(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feComponentTransfer", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feComposite(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feComposite", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feComposite(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feComposite", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feComposite(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feComposite", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feComposite(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feComposite", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feDiffuseLighting(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feDiffuseLighting", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDiffuseLighting(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feDiffuseLighting", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDiffuseLighting(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feDiffuseLighting", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDiffuseLighting(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feDiffuseLighting", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feBlend(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feBlend", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feBlend(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feBlend", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feBlend(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feBlend", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feBlend(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feBlend", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feColorMatrix(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feColorMatrix", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feColorMatrix(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feColorMatrix", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feColorMatrix(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feColorMatrix", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feColorMatrix(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feColorMatrix", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feConvolveMatrix(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feConvolveMatrix", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feConvolveMatrix(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feConvolveMatrix", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feConvolveMatrix(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feConvolveMatrix", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feConvolveMatrix(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feConvolveMatrix", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feDisplacementMap(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feDisplacementMap", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDisplacementMap(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feDisplacementMap", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDisplacementMap(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feDisplacementMap", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDisplacementMap(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feDisplacementMap", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feDistantLight(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feDistantLight", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDistantLight(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feDistantLight", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDistantLight(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feDistantLight", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDistantLight(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feDistantLight", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feDropShadow(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feDropShadow", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDropShadow(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feDropShadow", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDropShadow(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feDropShadow", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feDropShadow(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feDropShadow", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feFlood(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feFlood", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFlood(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feFlood", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFlood(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feFlood", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFlood(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feFlood", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feFuncA(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feFuncA", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncA(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feFuncA", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncA(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feFuncA", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncA(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feFuncA", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feFuncB(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feFuncB", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncB(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feFuncB", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncB(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feFuncB", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncB(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feFuncB", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feFuncG(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feFuncG", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncG(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feFuncG", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncG(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feFuncG", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncG(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feFuncG", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feFuncR(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feFuncR", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncR(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feFuncR", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncR(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feFuncR", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feFuncR(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feFuncR", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feGaussianBlur(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feGaussianBlur", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feGaussianBlur(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feGaussianBlur", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feGaussianBlur(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feGaussianBlur", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feGaussianBlur(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feGaussianBlur", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feImage(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feImage", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feImage(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feImage", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feImage(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feImage", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feImage(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feImage", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feMerge(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feMerge", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feMerge(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feMerge", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feMerge(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feMerge", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feMerge(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feMerge", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feMergeNode(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feMergeNode", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feMergeNode(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feMergeNode", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feMergeNode(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feMergeNode", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feMergeNode(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feMergeNode", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feMorphology(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feMorphology", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feMorphology(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feMorphology", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feMorphology(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feMorphology", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feMorphology(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feMorphology", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feOffset(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feOffset", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feOffset(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feOffset", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feOffset(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feOffset", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feOffset(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feOffset", [args...], Pair{Symbol,Any}[attrs...])
  end

  function fePointLight(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "fePointLight", [args...], Pair{Symbol,Any}[attrs...])
  end
  function fePointLight(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "fePointLight", [args...], Pair{Symbol,Any}[attrs...])
  end
  function fePointLight(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "fePointLight", [args...], Pair{Symbol,Any}[attrs...])
  end
  function fePointLight(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "fePointLight", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feSpecularLighting(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feSpecularLighting", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feSpecularLighting(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feSpecularLighting", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feSpecularLighting(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feSpecularLighting", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feSpecularLighting(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feSpecularLighting", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feSpotLight(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feSpotLight", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feSpotLight(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feSpotLight", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feSpotLight(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feSpotLight", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feSpotLight(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feSpotLight", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feTile(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feTile", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feTile(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feTile", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feTile(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feTile", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feTile(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feTile", [args...], Pair{Symbol,Any}[attrs...])
  end

  function feTurbulence(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "feTurbulence", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feTurbulence(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "feTurbulence", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feTurbulence(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "feTurbulence", [args...], Pair{Symbol,Any}[attrs...])
  end
  function feTurbulence(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "feTurbulence", [args...], Pair{Symbol,Any}[attrs...])
  end

  function foreignObject(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "foreignObject", [args...], Pair{Symbol,Any}[attrs...])
  end
  function foreignObject(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "foreignObject", [args...], Pair{Symbol,Any}[attrs...])
  end
  function foreignObject(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "foreignObject", [args...], Pair{Symbol,Any}[attrs...])
  end
  function foreignObject(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "foreignObject", [args...], Pair{Symbol,Any}[attrs...])
  end

  function g(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "g", [args...], Pair{Symbol,Any}[attrs...])
  end
  function g(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "g", [args...], Pair{Symbol,Any}[attrs...])
  end
  function g(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "g", [args...], Pair{Symbol,Any}[attrs...])
  end
  function g(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "g", [args...], Pair{Symbol,Any}[attrs...])
  end

  function hatch(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "hatch", [args...], Pair{Symbol,Any}[attrs...])
  end
  function hatch(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "hatch", [args...], Pair{Symbol,Any}[attrs...])
  end
  function hatch(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "hatch", [args...], Pair{Symbol,Any}[attrs...])
  end
  function hatch(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "hatch", [args...], Pair{Symbol,Any}[attrs...])
  end

  function hatchpath(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "hatchpath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function hatchpath(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "hatchpath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function hatchpath(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "hatchpath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function hatchpath(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "hatchpath", [args...], Pair{Symbol,Any}[attrs...])
  end

  function image(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "image", [args...], Pair{Symbol,Any}[attrs...])
  end
  function image(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "image", [args...], Pair{Symbol,Any}[attrs...])
  end
  function image(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "image", [args...], Pair{Symbol,Any}[attrs...])
  end
  function image(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "image", [args...], Pair{Symbol,Any}[attrs...])
  end

  function line(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "line", [args...], Pair{Symbol,Any}[attrs...])
  end
  function line(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "line", [args...], Pair{Symbol,Any}[attrs...])
  end
  function line(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "line", [args...], Pair{Symbol,Any}[attrs...])
  end
  function line(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "line", [args...], Pair{Symbol,Any}[attrs...])
  end

  function linearGradient(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "linearGradient", [args...], Pair{Symbol,Any}[attrs...])
  end
  function linearGradient(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "linearGradient", [args...], Pair{Symbol,Any}[attrs...])
  end
  function linearGradient(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "linearGradient", [args...], Pair{Symbol,Any}[attrs...])
  end
  function linearGradient(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "linearGradient", [args...], Pair{Symbol,Any}[attrs...])
  end

  function marker(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "marker", [args...], Pair{Symbol,Any}[attrs...])
  end
  function marker(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "marker", [args...], Pair{Symbol,Any}[attrs...])
  end
  function marker(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "marker", [args...], Pair{Symbol,Any}[attrs...])
  end
  function marker(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "marker", [args...], Pair{Symbol,Any}[attrs...])
  end

  function mask(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "mask", [args...], Pair{Symbol,Any}[attrs...])
  end
  function mask(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "mask", [args...], Pair{Symbol,Any}[attrs...])
  end
  function mask(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "mask", [args...], Pair{Symbol,Any}[attrs...])
  end
  function mask(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "mask", [args...], Pair{Symbol,Any}[attrs...])
  end

  function metadata(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "metadata", [args...], Pair{Symbol,Any}[attrs...])
  end
  function metadata(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "metadata", [args...], Pair{Symbol,Any}[attrs...])
  end
  function metadata(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "metadata", [args...], Pair{Symbol,Any}[attrs...])
  end
  function metadata(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "metadata", [args...], Pair{Symbol,Any}[attrs...])
  end

  function mpath(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "mpath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function mpath(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "mpath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function mpath(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "mpath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function mpath(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "mpath", [args...], Pair{Symbol,Any}[attrs...])
  end

  function path(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "path", [args...], Pair{Symbol,Any}[attrs...])
  end
  function path(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "path", [args...], Pair{Symbol,Any}[attrs...])
  end
  function path(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "path", [args...], Pair{Symbol,Any}[attrs...])
  end
  function path(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "path", [args...], Pair{Symbol,Any}[attrs...])
  end

  function pattern(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "pattern", [args...], Pair{Symbol,Any}[attrs...])
  end
  function pattern(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "pattern", [args...], Pair{Symbol,Any}[attrs...])
  end
  function pattern(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "pattern", [args...], Pair{Symbol,Any}[attrs...])
  end
  function pattern(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "pattern", [args...], Pair{Symbol,Any}[attrs...])
  end

  function polygon(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "polygon", [args...], Pair{Symbol,Any}[attrs...])
  end
  function polygon(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "polygon", [args...], Pair{Symbol,Any}[attrs...])
  end
  function polygon(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "polygon", [args...], Pair{Symbol,Any}[attrs...])
  end
  function polygon(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "polygon", [args...], Pair{Symbol,Any}[attrs...])
  end

  function polyline(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "polyline", [args...], Pair{Symbol,Any}[attrs...])
  end
  function polyline(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "polyline", [args...], Pair{Symbol,Any}[attrs...])
  end
  function polyline(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "polyline", [args...], Pair{Symbol,Any}[attrs...])
  end
  function polyline(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "polyline", [args...], Pair{Symbol,Any}[attrs...])
  end

  function radialGradient(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "radialGradient", [args...], Pair{Symbol,Any}[attrs...])
  end
  function radialGradient(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "radialGradient", [args...], Pair{Symbol,Any}[attrs...])
  end
  function radialGradient(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "radialGradient", [args...], Pair{Symbol,Any}[attrs...])
  end
  function radialGradient(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "radialGradient", [args...], Pair{Symbol,Any}[attrs...])
  end

  function rect(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "rect", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rect(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "rect", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rect(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "rect", [args...], Pair{Symbol,Any}[attrs...])
  end
  function rect(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "rect", [args...], Pair{Symbol,Any}[attrs...])
  end

  function set(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "set", [args...], Pair{Symbol,Any}[attrs...])
  end
  function set(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "set", [args...], Pair{Symbol,Any}[attrs...])
  end
  function set(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "set", [args...], Pair{Symbol,Any}[attrs...])
  end
  function set(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "set", [args...], Pair{Symbol,Any}[attrs...])
  end

  function stop(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "stop", [args...], Pair{Symbol,Any}[attrs...])
  end
  function stop(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "stop", [args...], Pair{Symbol,Any}[attrs...])
  end
  function stop(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "stop", [args...], Pair{Symbol,Any}[attrs...])
  end
  function stop(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "stop", [args...], Pair{Symbol,Any}[attrs...])
  end

  function svg(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "svg", [args...], Pair{Symbol,Any}[attrs...])
  end
  function svg(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "svg", [args...], Pair{Symbol,Any}[attrs...])
  end
  function svg(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "svg", [args...], Pair{Symbol,Any}[attrs...])
  end
  function svg(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "svg", [args...], Pair{Symbol,Any}[attrs...])
  end

  function switch(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "switch", [args...], Pair{Symbol,Any}[attrs...])
  end
  function switch(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "switch", [args...], Pair{Symbol,Any}[attrs...])
  end
  function switch(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "switch", [args...], Pair{Symbol,Any}[attrs...])
  end
  function switch(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "switch", [args...], Pair{Symbol,Any}[attrs...])
  end

  function symbol(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "symbol", [args...], Pair{Symbol,Any}[attrs...])
  end
  function symbol(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "symbol", [args...], Pair{Symbol,Any}[attrs...])
  end
  function symbol(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "symbol", [args...], Pair{Symbol,Any}[attrs...])
  end
  function symbol(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "symbol", [args...], Pair{Symbol,Any}[attrs...])
  end

  function text(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "text", [args...], Pair{Symbol,Any}[attrs...])
  end
  function text(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "text", [args...], Pair{Symbol,Any}[attrs...])
  end
  function text(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "text", [args...], Pair{Symbol,Any}[attrs...])
  end
  function text(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "text", [args...], Pair{Symbol,Any}[attrs...])
  end

  function textPath(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "textPath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function textPath(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "textPath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function textPath(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "textPath", [args...], Pair{Symbol,Any}[attrs...])
  end
  function textPath(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "textPath", [args...], Pair{Symbol,Any}[attrs...])
  end

  function tspan(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "tspan", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tspan(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "tspan", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tspan(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "tspan", [args...], Pair{Symbol,Any}[attrs...])
  end
  function tspan(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "tspan", [args...], Pair{Symbol,Any}[attrs...])
  end

  function use(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "use", [args...], Pair{Symbol,Any}[attrs...])
  end
  function use(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "use", [args...], Pair{Symbol,Any}[attrs...])
  end
  function use(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "use", [args...], Pair{Symbol,Any}[attrs...])
  end
  function use(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "use", [args...], Pair{Symbol,Any}[attrs...])
  end

  function view(f::Function, args...; attrs...) :: ParsedHTMLString
    normal_element(f, "view", [args...], Pair{Symbol,Any}[attrs...])
  end
  function view(children::Union{String,Vector{String}} = "", args...; attrs...) :: ParsedHTMLString
    normal_element(children, "view", [args...], Pair{Symbol,Any}[attrs...])
  end
  function view(children::Any, args...; attrs...) :: ParsedHTMLString
    normal_element(string(children), "view", [args...], Pair{Symbol,Any}[attrs...])
  end
  function view(children::Vector{Any}, args...; attrs...) :: ParsedHTMLString
    normal_element([string(c) for c in children], "view", [args...], Pair{Symbol,Any}[attrs...])
  end


