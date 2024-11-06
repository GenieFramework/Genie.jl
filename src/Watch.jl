module Watch

using Revise
using Genie
using Logging
using Dates

const WATCHED_FOLDERS = Ref{Vector{String}}(String[])
const WATCHING = Ref{Vector{UInt}}(UInt[])
const WATCH_HANDLERS = Ref{Dict{String,Vector{Function}}}(Genie.config.watch_handlers)

function collect_watched_files(files::Vector{S} = WATCHED_FOLDERS[], extensions::Vector{S} = Genie.config.watch_extensions)::Vector{S} where {S<:AbstractString}
  result = String[]

  for f in files
    push!(result, Genie.Util.walk_dir(f, only_extensions = extensions)...)
  end

  result |> sort |> unique
end

function watchpath(path::Union{S,Vector{S}}) where {S<:AbstractString}
  isa(path, Vector) || (path = String[path])
  push!(WATCHED_FOLDERS[], path...)
  unique!(WATCHED_FOLDERS[])
end

function delete_handlers(key::Any)
  delete!(WATCH_HANDLERS[], string(key))
end

function add_handler!(key::S, handler::F) where {F<:Function, S<:AbstractString}
  haskey(WATCH_HANDLERS[], key) || (WATCH_HANDLERS[][key] = Function[])
  push!(WATCH_HANDLERS[][key], handler)
  unique!(WATCH_HANDLERS[][key])
end

function handlers!(key::S, handlers::Vector{<: Function}) where {S<:AbstractString}
  WATCH_HANDLERS[][key] = handlers
end

function handlers() :: Vector{<: Function}
  WATCH_HANDLERS[] |> values |> collect |> Iterators.flatten |> collect
end

function watched_files_have_changed(files::Vector{<: AbstractString}) :: Bool
  files != collect_watched_files(WATCHED_FOLDERS[])
end

function watch( files::Vector{<: AbstractString},
                extensions::Vector{<: AbstractString} = Genie.config.watch_extensions;
                handlers::Vector{<: Function} = handlers(),
                watch_frequency::Int = Genie.config.watch_frequency # in milliseconds
              ) :: Nothing
  watchpath(files) # add the files to the watch list

  last_watched = now() - Millisecond(watch_frequency) # to trigger the first watch

  Genie.Configuration.isdev() && Revise.revise()

  watched_files = collect_watched_files(WATCHED_FOLDERS[], extensions)
  try
    @async entr(watched_files; all = true) do
      now() - last_watched > Millisecond(watch_frequency) || return
      last_watched = now()

      try
        for f in unique!(handlers)
          Base.invokelatest(f)
        end
      catch ex
        @error ex
      end

      last_watched = now()
    end |> errormonitor # entr
  catch ex
    @error ex
  end

  @async begin
    while true
      sleep(Genie.config.watch_frequency / 100)
      if watched_files_have_changed(watched_files)
        watched_files = collect_watched_files(WATCHED_FOLDERS[], extensions)
        watch(files, extensions; handlers = handlers, watch_frequency = watch_frequency)
        break
      end
    end
  end

  nothing
end

function watch(handler::F, files::Union{A,Vector{A}}, extensions::Vector{A} = Genie.config.watch_extensions) where {F<:Function, A<:AbstractString}
  isa(files, Vector) || (files = String[files])
  watch(files, extensions; handlers = Function[handler])
end

watch(files::A, extensions::Vector{A} = Genie.config.watch_extensions; handlers::Vector{F} = handlers()) where {F<:Function, A<:AbstractString} = watch(String[files], extensions; handlers)
watch(files...; extensions::Vector{A} = Genie.config.watch_extensions, handlers::Vector{F} = handlers()) where {F<:Function, A<:AbstractString} = watch(String[files...], extensions; handlers)
watch() = watch(String[])

function unwatch(files::Vector{A})::Nothing where {A<:AbstractString}
  filter!(e -> !(e in files), WATCHED_FOLDERS[])

  nothing
end
unwatch(files...) = unwatch(String[files...])

end