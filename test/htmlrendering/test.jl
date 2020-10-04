using Pkg
Pkg.activate(".")

using Genie, Genie.Router, Genie.Renderer, Genie.Renderer.Html

markup = """<button class="nes-btn" id="submit-button">Go!</button>"""
markup *= """<label for="whatever"></label>"""

route("/") do
  html(markup)
end

Genie.AppServer.startup(; open_browser = false, async = false)
