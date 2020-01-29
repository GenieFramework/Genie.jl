using Pkg
Pkg.activate(".")

using Genie, Genie.Router, Genie.Renderer

markup = """<button class="nes-btn" id="submit-button">Go!</button>"""
markup *= """<label for="whatever"></label>"""

route("/") do
  html(markup)
end

Genie.AppServer.startup(async = false)
