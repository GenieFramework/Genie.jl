module MdHtml

using Genie
using Markdown
import Genie.Renderer: vars

const MD_SEPARATOR_START = "---"
const MD_SEPARATOR_END   = "---"


function md_to_html(path::String; context::Module = @__MODULE__) :: String
  Genie.Renderer.build_module(
"""
<%
Base.include_string(context,
\"\"\"
\\\"\\\"\\\"
$(eval_markdown(read(path, String), context = context))
\\\"\\\"\\\"
\"\"\") |> Markdown.parse |> Markdown.html
%>
\n""",
    joinpath(Genie.config.path_build, Genie.Renderer.BUILD_NAME, path),
    string(hash(path), ".html"),
    output_path = false
  )
end


"""
    eval_markdown(md::String; context::Module = @__MODULE__) :: String

Converts the mardown `md` to HTML view code.
"""
function eval_markdown(md::String; context::Module = @__MODULE__) :: String
  if startswith(md, string(MD_SEPARATOR_START, "\n"))
    close_sep_pos = findfirst(MD_SEPARATOR_END, md[length(MD_SEPARATOR_START)+1:end])
    metadata = md[length(MD_SEPARATOR_START)+1:close_sep_pos[end]] |> YAML.load

    isa(metadata, Dict) || (@warn "\nFound Markdown YAML metadata but it did not result in a `Dict` \nPlease check your markdown metadata \n$metadata")

    try
      for (k,v) in metadata
        vars()[Symbol(k)] = v
      end
    catch ex
      @error ex
    end

    md = replace(md[close_sep_pos[end]+length(MD_SEPARATOR_END)+1:end], "\"\"\""=>"\\\"\\\"\\\"")
  end

  md
end


end