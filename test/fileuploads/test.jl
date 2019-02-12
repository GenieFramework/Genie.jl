using Pkg
pkg"activate ."

using Genie, Genie.Router, Genie.Renderer

form = """
<form action="/" method="POST" enctype="multipart/form-data">
  <input type="text" name="greeting" value="hello genie" />
  <input type="file" name="fileupload" />
  <input type="submit" value="upload" />
</form>
"""

layout = "<? @yield ?>"

route("/") do
  html!(form)
end

route("/", method = POST) do
  if ! isempty(@params(:FILES))
    for (label,file) in @params(:FILES)
      write(file.name, IOBuffer(file.data))
    end
  end
  @show @params(:greeting)

  @params(:greeting)
end

Genie.AppServer.startup(async = false)
