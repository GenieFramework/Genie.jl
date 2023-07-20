module Js

import Logging, HTTP, Reexport

Reexport.@reexport using Genie
Reexport.@reexport using Genie.Renderer
using Genie.Context

const JS_FILE_EXT   = ".jl"
const TEMPLATE_EXT  = ".jl.js"

const SUPPORTED_JS_OUTPUT_FILE_FORMATS = [TEMPLATE_EXT]

const JSString = String

const NBSP_REPLACEMENT = ("&nbsp;"=>"!!nbsp;;")

export js


function get_template(path::String; context::Module = @__MODULE__, vars...) :: Function
  orig_path = path

  path, extension = Genie.Renderer.view_file_info(path, SUPPORTED_JS_OUTPUT_FILE_FORMATS)

  if ! isfile(path)
    error_message = length(SUPPORTED_JS_OUTPUT_FILE_FORMATS) == 1 ?
                    """JS file "$orig_path$(SUPPORTED_JS_OUTPUT_FILE_FORMATS[1])" does not exist""" :
                    """JS file "$orig_path" with extensions $SUPPORTED_JS_OUTPUT_FILE_FORMATS does not exist"""
    error(error_message)
  end

  f_name = Genie.Renderer.function_name(path) |> Symbol
  mod_name = Genie.Renderer.m_name(path) * ".jl"
  f_path = joinpath(Genie.config.path_build, Genie.Renderer.BUILD_NAME, mod_name)
  f_stale = Genie.Renderer.build_is_stale(path, f_path)

  if f_stale || ! isdefined(context, f_name)
    f_stale && Genie.Renderer.build_module(to_js(read(path, String); extension), path, mod_name)

    return Base.include(context, joinpath(Genie.config.path_build, Genie.Renderer.BUILD_NAME, mod_name))
  end

  getfield(context, f_name)
end


function to_js(data::String; prepend = "\n", extension = TEMPLATE_EXT) :: String
  output = string("function $(Genie.Renderer.function_name(data))($(Genie.Renderer.injectkwvars())) :: String \n", prepend)

  output *= if extension == TEMPLATE_EXT
          "\"\"\"
          $data
          \"\"\""
  elseif extension == JS_FILE_EXT
    data
  else
    error("Unsuported template extension $extension")
  end

  string(output, "\nend \n")
end


function render(data::String; context::Module = @__MODULE__, vars...) :: Function
  Genie.Renderer.registervars(; context, vars...)

  data_hash = hash(data)
  path = "Genie_" * string(data_hash)

  func_name = Genie.Renderer.function_name(string(data_hash)) |> Symbol
  mod_name = Genie.Renderer.m_name(path) * ".jl"
  f_path = joinpath(Genie.config.path_build, Genie.Renderer.BUILD_NAME, mod_name)
  f_stale = Genie.Renderer.build_is_stale(f_path, f_path)

  if f_stale || ! isdefined(context, func_name)
    f_stale && Genie.Renderer.build_module(to_js(data), path, mod_name)

    return Base.include(context, joinpath(Genie.config.path_build, Genie.Renderer.BUILD_NAME, mod_name))
  end

  getfield(context, func_name)
end


function render(viewfile::Genie.Renderer.FilePath; context::Module = @__MODULE__, vars...)::Function
  Genie.Renderer.registervars(; context, vars...)

  get_template(string(viewfile); partial = false, context, vars...)
end


function render(::Type{MIME"application/javascript"},
                data::String;
                context::Module = @__MODULE__,
                params::Params = Params(),
                vars...)::Genie.Renderer.WebRenderable
  try
    Genie.Renderer.WebRenderable(render(data; context, vars...), :javascript, params)
  catch ex
    isa(ex, KeyError) && Genie.Renderer.changebuilds() # it's a view error so don't reuse them
    rethrow(ex)
  end
end


function render(::Type{MIME"application/javascript"},
                viewfile::Genie.Renderer.FilePath;
                context::Module = @__MODULE__,
                params::Params = Params(),
                vars...)::Genie.Renderer.WebRenderable
  try
    Genie.Renderer.WebRenderable(render(viewfile; context, vars...), :javascript, params)
  catch ex
    isa(ex, KeyError) && Genie.Renderer.changebuilds() # it's a view error so don't reuse them
    rethrow(ex)
  end
end


function js(data::String;
            context::Module = @__MODULE__, status::Int = 200,
            headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders("Content-Type" => Genie.Renderer.CONTENT_TYPES[:javascript]),
            forceparse::Bool = false,
            noparse::Bool = false,
            params::Params = Params(),
            vars...)::Genie.Renderer.HTTP.Response
  if (occursin(raw"$", data) || forceparse) && ! noparse
    Genie.Renderer.WebRenderable(render(MIME"application/javascript", data; context, vars...), :javascript, status, headers, params) |> Genie.Renderer.respond
  else
    js!(data; status, headers) |> Genie.Renderer.respond
  end
end

function js!(data::S;
              status::Int = 200,
              headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders("Content-Type" => Genie.Renderer.CONTENT_TYPES[:javascript]),
              params::Params = Params())::Genie.Renderer.HTTP.Response where {S<:AbstractString}
  Genie.Renderer.WebRenderable(data, :javascript, status, headers, params) |> Genie.Renderer.respond
end


function js(viewfile::Genie.Renderer.FilePath;
            context::Module = @__MODULE__,
            status::Int = 200,
            headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders("Content-Type" => Genie.Renderer.CONTENT_TYPES[:javascript]),
            params::Params = Params(),
            vars...) :: Genie.Renderer.HTTP.Response
  Genie.Renderer.WebRenderable(render(MIME"application/javascript", viewfile; context, vars...), :javascript, status, headers, params) |> Genie.Renderer.respond
end


### === ###
### EXCEPTIONS ###


function Genie.Router.error(error_message::String, ::Type{MIME"application/javascript"}, ::Val{500}; error_info::String = "") :: HTTP.Response
  HTTP.Response(Dict("error" => "500 Internal Error - $error_message", "info" => error_info), status = 500) |> js
end


function Genie.Router.error(error_message::String, ::Type{MIME"application/javascript"}, ::Val{404}; error_info::String = "") :: HTTP.Response
  HTTP.Response(Dict("error" => "404 Not Found - $error_message", "info" => error_info), status = 404) |> js
end


function Genie.Router.error(error_code::Int, error_message::String, ::Type{MIME"application/javascript"}; error_info::String = "") :: HTTP.Response
  HTTP.Response(Dict("error" => "$error_code Error - $error_message", "info" => error_info), status = error_code) |> js
end

end
