module LintFilesTask

using Genie, Util, Lint, Logger

function description()
  """
  Lints the files in the indicated dir
  """
end

function run_task!()
  dir = joinpath(Pkg.dir("Genie"), "src")
  for filename in Util.walk_dir(dir)
    @show filename
    try
      for message in lintfile(filename)
        color = if iserror(message)
                  :red
                elseif iswarning(message)
                  :orange
                elseif isinfo(message)
                  :blue
                end
        print_with_color(color, string(message) * "\n\n")
      end
    catch ex
      Logger.log(string(ex), :err)
    end
  end
end

end
