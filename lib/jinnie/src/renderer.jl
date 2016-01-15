type Renderer # TODO: refactor, this should not use empty strings but nullable types
  layout::AbstractString
  view::AbstractString

  Renderer(view::AbstractString) = new(abspath("app/views/layouts/application"), "")
  Renderer() = Renderer("")
end

function _render(layout_file::AbstractString, view_file::AbstractString, data::Dict, mime_format)
  view_stream = open(view_file)
  data["yield"] = eval(renderers[mime_format]).render(readall(view_stream), data)
  layout_stream = open(layout_file)
  eval(renderers[mime_format]).render(readall(layout_stream), data)
end

function render(req::Dict; mime="html", format="mustache", data=Dict())
  _render("$(renderer.layout).$mime.$format", "$(renderer.view).$mime.$format", data, "$mime.$format")
end



function render(content::AbstractString; data=Dict())
  Mustache.render(content, data)
end