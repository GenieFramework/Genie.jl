using Pkg
Pkg.activate(".")

using Genie, Genie.Router, Genie.Renderer, Genie.Renderer.Html

form = """
<form action="/" method="POST" enctype="multipart/form-data">
  <input type="text" name="greeting" value="hello genie" />
  <input type="submit" value="post" />
</form>
"""

layout = "<? @yield ?>"

route("/") do
  html(form)
end

route("/", method = POST) do
  @show @params

  @show @params(:greeting)

  @params(:greeting)
end

Genie.AppServer.startup(async = false)
