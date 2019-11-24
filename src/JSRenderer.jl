module JSRenderer


import Revise
import Logging, FilePaths
using Genie, Genie.Flax


const JS_FILE_EXT   = ["js.jl"]
const TEMPLATE_EXT  = [".flax.js", ".jl.js"]

const SUPPORTED_JS_OUTPUT_FILE_FORMATS = TEMPLATE_EXT

const JSString = String

const NBSP_REPLACEMENT = ("&nbsp;"=>"!!nbsp;;")

export JSString


"""
"""
function get_template(path::String; context::Module = @__MODULE__) :: Function
  orig_path = path

  path, extension = Flax.view_file_info(path, SUPPORTED_JS_OUTPUT_FILE_FORMATS)

  isfile(path) || error("JS file \"$orig_path\" with extensions $SUPPORTED_JS_OUTPUT_FILE_FORMATS does not exist")

  extension in JS_FILE_EXT && return (() -> Base.include(context, path))

  f_name = Flax.function_name(path) |> Symbol
  mod_name = Flax.m_name(path) * ".jl"
  f_path = joinpath(Genie.config.path_build, Flax.BUILD_NAME, mod_name)
  f_stale = Flax.build_is_stale(path, f_path)

  if f_stale || ! isdefined(context, func_name)
    f_stale && Flax.build_module(Flax.to_js(data), path, mod_name)

    return Base.include(context, joinpath(Genie.config.path_build, Flax.BUILD_NAME, mod_name))
  end

  getfield(context, f_name)
end


"""
"""
@inline function to_js(data::String; prepend = "\n") :: String
  string("function $(Flax.function_name(data))() \n",
          Flax.injectvars(),
          prepend,
          "\"\"\"$data\"\"\"",
          "\nend \n")
end


"""
"""
function render(data::String; context::Module = @__MODULE__, vars...) :: Function
  Flax.registervars(vars...)

  data_hash = hash(data)
  path = "Flax_" * string(data_hash)

  func_name = Flax.function_name(string(data_hash)) |> Symbol
  mod_name = Flax.m_name(path) * ".jl"
  f_path = joinpath(Genie.config.path_build, Flax.BUILD_NAME, mod_name)
  f_stale = Flax.build_is_stale(f_path, f_path)

  if f_stale || ! isdefined(context, func_name)
    f_stale && Flax.build_module(to_js(data), path, mod_name)

    return Base.include(context, joinpath(Genie.config.path_build, Flax.BUILD_NAME, mod_name))
  end

  getfield(context, func_name)
end


"""
"""
function render(viewfile::FilePaths.PosixPath; context::Module = @__MODULE__, vars...) :: Function
  Flax.registervars(vars...)

  get_template(string(viewfile), partial = false, context = context)
end

end