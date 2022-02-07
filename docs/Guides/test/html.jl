#=
This file is taken from: https://github.com/rikhuijzer/PlutoStaticHTML.jl/blob/main/src/PlutoStaticHTML.jl
in Oct 2021. The project has grown since with parallel builds/caching like features. 
Kindly use PlutoStaticHTML.jl instead.
=#

using Pluto:
    Cell,
    CellOutput,
    Notebook,
    ServerSession,
    SessionActions,
    generate_html,
    load_notebook_nobackup,
    update_run!,
    notebook_to_js

"""
    IMAGEMIME
Union of MIME image types.
Based on Pluto.PlutoRunner.imagemimes.
"""
const IMAGEMIME = Union{
    MIME"image/svg+xml",
    MIME"image/png",
    MIME"image/jpg",
    MIME"image/jpeg",
    MIME"image/bmp",
    MIME"image/gif"
}

"""
    _escape_html(s::AbstractString)
Escape HTML.
Useful for showing HTML inside code blocks, see
https://github.com/rikhuijzer/PlutoStaticHTML.jl/issues/9.
"""
function _escape_html(s::AbstractString)
    s = replace(s, "<pre>" => """<pre class="julia">""")
    s = replace(s, '<' => "&lt;")
    s = replace(s, '>' => "&gt;")
    return s
end

function code_block(code; class="language-julia")
    if code == ""
        return ""
    end
    code = _escape_html(code)
    return """<pre class="julia"><code class="$class">$code</code></pre>"""
end

function output_block(s; class="code-output")
    if s == ""
        return ""
    end
    return """<pre class="output"><code class="$class">$s</code></pre>"""
end

function _code2html(code::AbstractString, class, hide_md_code)
    if hide_md_code && startswith(code, "md\"")
        return ""
    end
    if contains(code, "# hideall")
        return ""
    end
    sep = '\n'
    lines = split(code, sep)
    filter!(!endswith("# hide"), lines)
    code = join(lines, sep)
    return code_block(code; class)
end

function _output2html(body, T::IMAGEMIME, class)
    encoded = base64encode(body)
    uri = "data:$T;base64,$encoded"
    return """<img src="$uri">"""
end

function _output2html(body, ::MIME"application/vnd.pluto.stacktracetobject", class)
    return error(body)
end

function _tr_wrap(elements::Vector)
    joined = join(elements, '\n')
    return "<tr>\n$joined\n</tr>"
end
_tr_wrap(::Array{String, 0}) = "<tr>\n<td>...</td>\n</tr>"

function _output2html(body::Dict{Symbol,Any}, ::MIME"application/vnd.pluto.table+object", class)
    rows = body[:rows]
    nms = body[:schema][:names]
    headers = _tr_wrap(["<th>$colname</th>" for colname in nms])
    contents = map(rows) do row
        # Drop index.
        row = row[2:end]
        # Unpack the type and throw away mime info.
        elements = try
            first.(only(row))
        catch
            first.(first.(row))
        end
        elements = ["<td>$e</td>" for e in elements]
        return _tr_wrap(elements)
    end
    content = join(contents, '\n')
    return """
        <table>
        $headers
        $content
        </table>
        """
end

abstract type Struct end

function symbol2type(s::Symbol)
    if s == :Tuple
        return Tuple
    elseif s == :Array
        return Array
    elseif s == :struct
        return Struct
    else
        @warn "Missing type: $s"
        return Missing
    end
end

"""
    _clean_tree(parent, element::Tuple{Any, Tuple{String, MIME}}, T)
Drop metadata.
For example, `(1, ("\"text\"", MIME type text/plain))` becomes "text".
"""
function _clean_tree(parent, element::Tuple{Any, Tuple{String, MIME}}, T)
    return first(last(element))
end

function _clean_tree(parent, element::Tuple{Any, Any}, T)
    embedded = first(last(element))
    if embedded isa String
        return embedded
    end
    struct_name = embedded[:prefix]
    elements = embedded[:elements]
    subelements = [_clean_tree(parent, e, Nothing) for e in elements]
    joined = join(subelements, ", ")
    return struct_name * '(' * joined * ')'
end

function _clean_tree(parent, elements::Tuple{Any, Tuple}, T)
    body = first(last(elements))
    T = symbol2type(body[:type])
    return _clean_tree(body, body[:elements], T)
end

function _clean_tree(parent, elements::AbstractVector, T::Type{Tuple})
    cleaned = [_clean_tree(parent, e, Nothing) for e in elements]
    joined = join(cleaned, ", ")
    return "($joined)"
end

function _clean_tree(parent, elements::AbstractVector, T::Type{Array})
    cleaned = [_clean_tree(parent, e, Nothing) for e in elements]
    joined = join(cleaned, ", ")
    return "[$joined]"
end

function _clean_tree(parent, elements::AbstractVector, T::Type{Struct})
    cleaned = [_clean_tree(parent, e, Nothing) for e in elements]
    joined = join(cleaned, ", ")
    return parent[:prefix] * '(' * joined * ')'
end

# Fallback. This shouldn't happen. Convert to string to avoid failure.
function _clean_tree(parent, elements, T)
    @warn "Couldn't convert $parent"
    return string(elements)::String
end

function _output2html(body::Dict{Symbol,Any}, ::MIME"application/vnd.pluto.tree+object", class)
    T = symbol2type(body[:type])
    cleaned = _clean_tree(body, body[:elements], T)
    return output_block(cleaned; class)
end

_output2html(body, ::MIME"text/plain", class) = output_block(body)
_output2html(body, ::MIME"text/html", class) = body
_output2html(body, T::MIME, class) = error("Unknown type: $T")

function _cell2html(cell::Cell, code_class, output_class, hide_md_code)
    code = _code2html(cell.code, code_class, hide_md_code)
    output = _output2html(cell.output.body, cell.output.mime, output_class)
    return """
        $code
        $output
        """
end

function run_notebook!(notebook, session)
    cells = [last(e) for e in notebook.cells_dict]
    update_run!(session, notebook, cells)
    return nothing
end


"""
    notebook2html(
        notebook::Notebook;
        session=ServerSession(),
        code_class="language-julia",
        output_class="code-output",
        hide_md_code=true
    )

Run the `notebook` and return the code and output as HTML.
"""
function notebook2html(
        notebook::Notebook;
        session=ServerSession(),
        code_class="language-julia",
        output_class="code-output",
        hide_md_code=true
    )


    cells = [last(e) for e in notebook.cells_dict]
    update_run!(session, notebook, cells)
    order = notebook.cell_order
    outputs = map(order) do cell_uuid
        cell = notebook.cells_dict[cell_uuid]
        _cell2html(cell, code_class, output_class, hide_md_code)
    end
    return join(outputs, '\n')
end

function notebook2htmlSessionActions(input)
    session = ServerSession();
    notebook = SessionActions.open(session, input; run_async=false)
    
    println("Type of: ", typeof(notebook.cells))
    println("Cell order", notebook.cell_order)
end

"""
    notebook2html2(notebook::Notebook)

Run the Pluto notebook and return the code and output as HTML.
"""
function notebook2html2(
    notebook::Notebook;
    code_class="language-julia",
    output_class="code-output",
    hide_md_code=true
    )

    cells = [last(e) for e in notebook.cells_dict]
    #update_run!(session, notebook, cells)
    order = notebook.cell_order
    outputs = map(order) do cell_uuid
        cell = notebook.cells_dict[cell_uuid]
        _cell2html(cell, code_class, output_class, hide_md_code)
    end
    return join(outputs, '\n')
end

function navbar(navbar::String; class="nav-box")

end

function upperwrap()
    return """<!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
      <!--Extra info-->
      <meta property="og:title" content="Genie Framework - Highly Productive Web Development with Julia"/>
      <meta property="og:description" content="Documentation for Genie Framework, the highly productive web development framework for Julia. It includes all you need to quickly build production ready web applications with Julia Lang."/>
      <meta property="og:image" itemprop="image" content="../assets/img/enviroment-website.svg">
      <link rel="icon" href="../assets/img/logo-genieframework.svg">
      <title>Documentation</title>

    
      <!-- Bootstrap Styles -->
      <link href="../assets/external/bootstrap-5.1.3-dist/css/bootstrap.min.css"  rel="stylesheet"></link>
    
      <!-- Font Awesome Styles -->
      <link href="../assets/external/fontawesome-free-6.0.0-beta3-web/css/fontawesome.min.css" rel="stylesheet"></link>
      <link href="../assets/external/fontawesome-free-6.0.0-beta3-web/css/solid.min.css" rel="stylesheet"></link>
      <link href="../assets/external/fontawesome-free-6.0.0-beta3-web/css/brands.min.css" rel="stylesheet"></link>
    
      <!-- Custom Styles -->
      <link rel="stylesheet" href="../assets/styles-docs.css">
    
      <!-- Highlight.js -->
      <link href="../assets/external/highlight/styles/xcode.min.css" rel="stylesheet"></link>
    
    </head>
    <body id="body-docs" onresize="windowResize()" class="d-flex flex-column min-vh-100" >

    
    <!-- N A V -->
      <div class="nav-box"></div>
      <div class="container-fluid nav-container">
        <div class="container py-1" style="max-width:1100px">
          <nav class="navbar navbar-expand-sm navbar-light m-auto"> 
            <a class="navbar-brand active" aria-current="page" href="https://genieframework.com/">
              <img src="../assets/img/logo-genieframework.svg" alt="GenieFramework" width="35" height="35" class="d-inline-block align-text-middle me-2">
              <h5 class="logoGenie">
                <span class="bold">Genie</span><span class="light very-squeezed">Framework</span>
              </h5>
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
              <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse justify-content-end" id="navbarNav">
              <ul class="navbar-nav">
                <!--<li class="nav-item contact-nav-item">
                  <a class="nav-link discord-nav-link ps-3 pe-0 py-1" href="https://discord.gg/9zyZbD6J7H" target="_blank">
                    <button class="button button-discord" aria-pressed="false">
                        <i class="fab fa-discord" id="discord-logo"></i> Join us on Discord 
                    </button>
                  </a>
                </li>-->
                <li class="nav-item dropdown">
                  <a class="nav-link dropdown-toggle px-4" href="#" id="navbarDarkDropdownMenuLink" role="button" data-bs-toggle="dropdown" aria-expanded="false">Join our Community
                  </a>
                  <ul class="dropdown-menu glassmorphism" aria-labelledby="navbarLightDropdownMenuLink">
                    <li><a class="dropdown-item " href="https://discord.gg/9zyZbD6J7H" target="_blank"><img class="icon-nav me-2" src="../assets/img/discord-contactus.svg" alt="discord"></img>Discord</a></li>
    
                    <li><a class="dropdown-item " href="https://github.com/GenieFramework" target="_blank"><img class="icon-nav me-2" src="../assets/img/github-contactus.svg" alt="github"></img>Github</a></li>
    
                    <li><a class="dropdown-item " href="https://gitter.im/essenciary/Genie.jl" target="_blank"><img class="icon-nav me-2" src="../assets/img/gitter-contactus.svg" alt="gitter"></img>Gitter</a></li>
                  </ul>
                </li>
              </ul>
            </div>
          </nav>
        </div>
      </div>
    <!-- B R E A D C R U M B  (D E S K T O P) -->
      <div class="container-fluid breadcrumb-desktop">
        <div class="container my-auto mx-auto breadcrumb-desktop">
          <p class="my-auto py-2">
              <a class="level-1-breadcrumb is-disabled" href="#">Getting Started</a>
              <span class="arrow px-2"> » </span>
              <a class="level-2-breadcrumb is-active" href="#">Welcome</a>
          </p>
        </div>
      </div>
    <!-- N A V 2  (M O B I L E) -->
      <div class="container-fluid py-2 px-4 flex-row justify-content-between nav2-mobile sticky-top">
        <div class="my-auto d-flex flex-start">
          <div id="hamburger" class="my-auto me-3" onclick="showSideBar()">
            <img src="../assets/img/hamburger.svg" alt="hamburger" width="25" >
          </div>
          <div class="my-auto">
            <h5 id="breadcrumb-mobile" class="my-0 me-3">Welcome</h5>
          </div>
        </div>
        <div class="my-auto loupe" onclick="showSearchBar()">
          <img id="loupe" src="../assets/img/loupe.svg" width="22" alt="loupe"></img>
        </div>
        <div id="searchbar" class="loupe my-auto ps-1 pe-2">
          <form class="docs-search" action="/docs/search.html"><input class="docs-search-query2 search" id="documenter-search-query2" name="q" type="text" placeholder="Search docs"/></form>
        </div>
        <div id="cancel" class="my-auto" onclick="hideSearchBar()">
          <img src="../assets/img/cancel.svg" alt="cancel" width="15">
        </div>
      </div>
    <!-- M A I N  C O N T E N T -->
      <div class="container-fluid" id="main-content">
        <div class="container content" id="documenter">
          <div class="darken" id="darken"></div>"""
end

#   <!-- M A I N  C O N T E N T -->
function wrap_output(my_output; class="container-fluid text")
    if my_output == ""
        return ""
    end
    return """<div class="$class">$my_output</div>"""
end

#   <!-- Lower Wrap -->

function lowerwrap()
    return """<!-- sidebar -->
    <aside class="container docs-sidebar" id="sidebar">
      <nav class="d-flex flex-column sidebar">
        <ul class="level-1 docs-menu">
      <div>
        <form class="docs-search" action="/docs/search.html"><input class="docs-search-query" id="documenter-search-query" name="q" type="text" placeholder="Search docs"/></form>
       </div>
        <!-- Genie -->
          <li class="genie">
            <a class="d-flex genie" data-bs-toggle="collapse" href="#collapse2" role="button" aria-expanded="true" aria-controls="collapse2">
              <img src="../assets/img/genie-lightblue.svg" class="genie-miniature" width="20" alt="Genie"></img>
                Genie
            </a>
            <div class="collapse show" id="collapse2">
              <ul class="level-2 genie">
                <li class="tutorials">
                  <a data-bs-toggle="collapse" href="#collapse2-1" role="button" aria-expanded="false" aria-controls="collapse2-1" class="is-active">Tutorials</a>
                  <div class="collapsable collapse" id="collapse2-1">
                    <ul class="level-3 genie">
                      <li>
                        <a class="tocitem" name="Overview" href="/docs/tutorials/Overview.html" onclick="hideSideBar()">Welcome to Genie</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Installing Genie" href="/docs/tutorials/Installing-Genie.html" onclick="hideSideBar()">Installing Genie</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Getting Started" href="/docs/tutorials/Getting-Started.html" onclick="hideSideBar()">Getting Started</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Developing Web Services" href="/docs/tutorials/Developing-Web-Services.html" onclick="hideSideBar()">Creating a Web service</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Developing MVC Web Apps" href="/docs/tutorials/Developing-MVC-Web-Apps.html" onclick="hideSideBar()">Developing MVC web applications</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Handling Query Params" href="/docs/tutorials/Handling-Query-Params.html" onclick="hideSideBar()">Handling URI/query params</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Working With POST Payloads" href="/docs/tutorials/Working-with-POST-Payloads.html" onclick="hideSideBar()">Working with forms and POST payloads</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Using JSON Payloads" href="/docs/tutorials/Using-JSON-Payloads.html" onclick="hideSideBar()">Using JSON payloads</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Handling File Uploads" href="/docs/tutorials/Handling-File-Uploads.html" onclick="hideSideBar()">Uploading files</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Publishing Your Julia Code Online With Genie Apps" href="/docs/tutorials/Publishing-Your-Julia-Code-Online-With-Genie-Apps.html" onclick="hideSideBar()">Adding your libraries into Genie</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Loading Genie Apps" href="/docs/tutorials/Loading-Genie-Apps.html" onclick="hideSideBar()">Loading and starting Genie apps</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Managing External Packages" href="/docs/tutorials/Managing-External-Packages.html" onclick="hideSideBar()">Managing Genie app's dependencies</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Advanced Routing Techniques" href="/docs/tutorials/Advanced-Routing-Techniques.html" onclick="hideSideBar()">Advanced routing</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Initializers" href="/docs/tutorials/Initializers.html" onclick="hideSideBar()">Auto-loading configuration code with initializers</a>
                      </li>
                      <li>
                        <a class="tocitem" name="The Secrets File" href="/docs/tutorials/The-Secrets-File.html" onclick="hideSideBar()">The secrets file</a>
                      </li>
                      <li>
                        <a class="tocitem" name="The Lib Folder" href="/docs/tutorials/The-Lib-Folder.html" onclick="hideSideBar()">Auto-loading user libraries</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Using Genie With Docker" href="/docs/tutorials/Using-Genie-With-Docker.html" onclick="hideSideBar()">Using Genie with Docker</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Working With Web Sockets" href="/docs/tutorials/Working-with-Web-Sockets.html" onclick="hideSideBar()">Working with Web Sockets</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Force Compiling Routes" href="/docs/tutorials/Force-Compiling-Routes.html" onclick="hideSideBar()">Force compiling route handlers</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Deploying With Heroku Buildpacks" href="/docs/tutorials/Deploying-With-Heroku-Buildpacks.html" onclick="hideSideBar()">Deploying to Heroku with Buildpacks</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Deploying Genie Server Apps With Nginx" href="/docs/tutorials/Deploying-Genie-Server-Apps-with-Nginx.html" onclick="hideSideBar()">Deploying to Heroku with Nginx</a>
                      </li>
                    </ul>
                  </div>
                </li>
                <li class="guides">
                  <a data-bs-toggle="collapse" href="#collapse2-3" role="button" aria-expanded="false" aria-controls="collapse2-3">Guides
                  </a>
                  <div class="collapsable collapse" id="collapse2-3">
                    <ul class="level-3 genie">
                      <li>
                        <a class="tocitem" name="Working With Genie Apps" href="/docs/guides/Working-With-Genie-Apps.html" onclick="hideSideBar()">Working with Genie apps</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Genie Plugins" href="/docs/guides/Genie-Plugins.html" onclick="hideSideBar()">Using Genie Plugins</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Simple API Backend" href="/docs/guides/Simple-API-backend.html" onclick="hideSideBar()">Developing an API backend</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Interactive Environment" href="/docs/guides/Interactive-environment.html" onclick="hideSideBar()">Using Genie in an interactive environment</a>
                      </li>
                    </ul>
                  </div>
                </li>
                <li class="api">
                  <a data-bs-toggle="collapse" href="#collapse2-4" role="button" aria-expanded="false" aria-controls="collapse2-4">APIs
                  </a>
                  <div class="collapsable collapse" id="collapse2-4">
                    <ul class="level-3 genie">
                      <li>
                          <a class="tocitem" name="App" onclick="hideSideBar()" href="/docs/api/app.html">App</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Appserver" onclick="hideSideBar()" href="/docs/api/appserver.html">AppServer</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Assets" onclick="hideSideBar()" href="/docs/api/assets.html">Assets</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Cache" onclick="hideSideBar()" href="/docs/api/cache.html">Cache</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Commands" onclick="hideSideBar()" href="/docs/api/commands.html">Commands</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Configuration" onclick="hideSideBar()" href="/docs/api/configuration.html">Configuration</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Cookies" onclick="hideSideBar()" href="/docs/api/cookies.html">Cookies</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Deploy Docker" onclick="hideSideBar()" href="/docs/api/deploy-docker.html">Deploy Docker</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Deploy Heroku" onclick="hideSideBar()" href="/docs/api/deploy-heroku.html">Deploy Heroku</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Encryption" onclick="hideSideBar()" href="/docs/api/encryption.html">Encryption</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Exceptions" onclick="hideSideBar()" href="/docs/api/exceptions.html">Exceptions</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Filetemplates" onclick="hideSideBar()" href="/docs/api/filetemplates.html">FileTemplates</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Flash" onclick="hideSideBar()" href="/docs/api/flash.html">Flash</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Generator" onclick="hideSideBar()" href="/docs/api/generator.html">Generator</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Genie" onclick="hideSideBar()" href="/docs/api/genie.html">Genie</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Headers" onclick="hideSideBar()" href="/docs/api/headers.html">Headers</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Httputils" onclick="hideSideBar()" href="/docs/api/httputils.html">HttpUtils</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Inflector" onclick="hideSideBar()" href="/docs/api/inflector.html">Inflector</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Input" onclick="hideSideBar()" href="/docs/api/input.html">Input</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Plugins" onclick="hideSideBar()" href="/docs/api/plugins.html">Plugins</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Renderer" onclick="hideSideBar()" href="/docs/api/renderer.html">Renderer</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Renderer Html" onclick="hideSideBar()" href="/docs/api/renderer-html.html">HTML Renderer</a>
                      </li>
                      <li>
                        <a class="tocitem" name="Renderer Js" onclick="hideSideBar()" href="/docs/api/renderer-js.html">JS Renderer</a>
                    </li>
                      <li>
                          <a class="tocitem" name="Renderer Json" onclick="hideSideBar()" href="/docs/api/renderer-json.html">JSON Renderer</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Requests" onclick="hideSideBar()" href="/docs/api/requests.html">Requests</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Responses" onclick="hideSideBar()" href="/docs/api/responses.html">Responses</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Router" onclick="hideSideBar()" href="/docs/api/router.html">Router</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Sessions" onclick="hideSideBar()" href="/docs/api/sessions.html">Sessions</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Toolbox" onclick="hideSideBar()" href="/docs/api/toolbox.html">Toolbox</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Util" onclick="hideSideBar()" href="/docs/api/util.html">Util</a>
                      </li>
                      <li>
                          <a class="tocitem" name="Webchannels" onclick="hideSideBar()" href="/docs/api/webchannels.html">WebChannels</a>
                      </li>
                    </ul>
                  </div>
                </li>
              </ul>
            </div>
          </li>
        </ul>
      </nav>
    </aside>
  </div>
</div>
<!-- F O O T E R -->
<footer class="py-5 px-3 mt-auto">
  <div class="container p-2">
      <div class="corporative-footer pt-2 pb-4">
          <h6 class="footer mb-1"><span class="bold">Genie</span><span class="light very-squeezed">Framework</span></h6>
          <small>©2022 | All rights reserved</small>
          
      </div>
      <div class="list-footer d-flex pt-2 pb-3">
          <div class="index-footer">
              <ul>
                  <li><a href="/docs/tutorials/Overview.html" target="_blank">Docs</a></li>
                  <li><a href="https://genieframework.com/" target="_blank">Genie Framework</a></li>
              </ul>
          </div>
      </div>
      <div class="socialmedia-footer pt-2">
          <p>📣 Discover the Genie community through our social media channels</p>
          <div class="icons-footer">
              <a href="https://discord.gg/9zyZbD6J7H" target="_blank"><img class="icon" src="../assets/img/discord-contactus.svg" alt="discord"></a>
              <a href="https://github.com/GenieFramework" target="_blank"><img class="icon" src="../assets/img/github-contactus.svg" alt="github"></a>
              <a href="https://gitter.im/essenciary/Genie.jl" target="_blank"><img class="icon" src="../assets/img/gitter-contactus.svg" alt="gitter"></a>
              <a href="https://twitter.com/geniemvc?lang=en" target="_blank"><img class="icon" src="../assets/img/twitter-contactus.svg" alt="twitter"></a>
          </div>
      </div>
  </div>
</footer>      
<script src="../assets/external/bootstrap-5.1.3-dist/js/bootstrap.min.js"></script>

<script src="../assets/external/highlight/highlight.min.js"></script>
<script>hljs.highlightAll();</script>

<script src="../assets/external/clipboard.js-master/dist/clipboard.min.js"></script>

<script src="../assets/external/fontawesome-free-6.0.0-beta3-web/js/fontawesome.min.js"></script>
<script src="../assets/external/fontawesome-free-6.0.0-beta3-web/js/all.js"></script>

<script async defer src="https://buttons.github.io/buttons.js"></script>

<!--NAV2 Searchbar & Asidebar-->
<script type="text/javascript" src="../assets/searchBar&sideBar.js"></script>

<!-- Copy Code -->
<script type="text/javascript" src="../assets/copy&output.js"></script>

<!-- Breadcrum dynamic label logic -->
<script src="../assets/breadcrumb&title.js"></script>

<!-- Content Asidebar -->
<script src="../assets/asidebar.js"></script>

 <!-- Search results-->
 <script src="../assets/search/search_index.js"></script><script src="../assets/search/search.js"></script>
</body>
</html>"""
end


# Final page
function body(notebook::Notebook)
    return join(upperwrap() * wrap_output(notebook2html2(notebook::Notebook)) * lowerwrap())
end

export notebook2html2, run_notebook!, body