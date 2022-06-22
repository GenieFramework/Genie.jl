module Watch

using Revise
using Genie

const _task = Ref{Core.Task}()
const WATCHED_FOLDERS = Ref{Vector{String}}(String[])

function collect_watched_files(files::Vector{String} = String[],
                                extensions::Vector{String} = Genie.config.watch_extensions) :: Vector{String}
  result = String[]

  for f in files
    try
      push!(result, Genie.Util.walk_dir(f, only_extensions = extensions)...)
    catch ex
      @error ex
    end
  end

  result |> unique!
end

function handlers()
  Genie.config.watch_handlers |> values |> collect
end

function watch(files::Vector{String}, extensions::Vector{String} = Genie.config.watch_extensions) :: Nothing
  push!(WATCHED_FOLDERS[], files...)
  WATCHED_FOLDERS[] = unique(WATCHED_FOLDERS[])

  @info "Monitoring $files for changes"

  Revise.revise()

  _task[] = @async entr(collect_watched_files(files, extensions); all = true, postpone = true) do
    @info "Detected files changes"

    for fg in handlers()
      for f in fg
        try
          Base.invokelatest(f)
        catch ex
          @error ex
        end
      end
    end
  end

  nothing
end

watch(files::String, extensions::Vector{String} = Genie.config.watch_extensions) = watch(String[files], extensions)
watch(files...; extensions::Vector{String} = Genie.config.watch_extensions) = watch(String[files...], extensions)
watch() = watch(String[])

function unwatch(files::Vector{String}) :: Nothing
  filter!(e -> !(e in files), WATCHED_FOLDERS[])
  watch()
end
unwatch(files...) = unwatch(String[files...])

end