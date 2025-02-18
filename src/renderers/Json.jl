module Json

import JSON3, HTTP, Reexport

Reexport.@reexport using Genie
Reexport.@reexport using Genie.Renderer

module JSONParser

import JSON3

parse(x, args...; kwargs...) = JSON3.read(x, args...; kwargs...)
parse(x::AbstractString, args...; kwargs...) = JSON3.read(codeunits(x), args...; kwargs...)

const json = JSON3.write

# ugly but necessary
JSON3.StructTypes.StructType(::T) where {T<:DataType} = JSON3.StructTypes.Struct()

end

using .JSONParser

const JSON = JSONParser
const JSON_FILE_EXT = ".json.jl"
const JSONString = String

export JSONString, json, parse, JSONException

Base.@kwdef mutable struct JSONException <: Exception
  status::Int
  message::String
end

function render(viewfile::Genie.Renderer.FilePath; context::Module = @__MODULE__, vars...) :: Function
  Genie.Renderer.registervars(; context = context, vars...)

  path = viewfile |> string
  partial = true

  f_name = Genie.Renderer.function_name(string(path, partial)) |> Symbol
  mod_name = Genie.Renderer.m_name(string(path, partial)) * ".jl"
  f_path = joinpath(Genie.config.path_build, Genie.Renderer.BUILD_NAME, mod_name)
  f_stale = Genie.Renderer.build_is_stale(path, f_path)

  if f_stale || ! isdefined(context, f_name)
    Genie.Renderer.build_module(
      Genie.Renderer.Html.to_julia(read(path, String), nothing, partial = partial, f_name = f_name),
      path,
      mod_name,
      output_path = false
    )

    Base.include(context, f_path)
  end

  () -> try
    getfield(context, f_name)() |> first
  catch ex
    if isa(ex, MethodError) && string(ex.f) == string(f_name)
      Base.invokelatest(getfield(context, f_name)) |> first
    else
      rethrow(ex)
    end
  end |> JSONParser.json
end


function render(data::Any; forceparse::Bool = false, context::Module = @__MODULE__) :: Function
  () -> JSONParser.json(data)
end


function Genie.Renderer.render(::Type{MIME"application/json"}, datafile::Genie.Renderer.FilePath; context::Module = @__MODULE__, vars...) :: Genie.Renderer.WebRenderable
  Genie.Renderer.WebRenderable(render(datafile; context = context, vars...), :json)
end


function Genie.Renderer.render(::Type{MIME"application/json"}, data::String; context::Module = @__MODULE__, vars...) :: Genie.Renderer.WebRenderable
  Genie.Renderer.WebRenderable(render(data; context = context, vars...), :json)
end


function Genie.Renderer.render(::Type{MIME"application/json"}, data::Any; context::Module = @__MODULE__, vars...) :: Genie.Renderer.WebRenderable
  Genie.Renderer.WebRenderable(render(data), :json)
end

### json API

function json(resource::Genie.Renderer.ResourcePath, action::Genie.Renderer.ResourcePath; context::Module = @__MODULE__,
              status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders(), vars...) :: Genie.Renderer.HTTP.Response
  json(Genie.Renderer.Path(joinpath(Genie.config.path_resources, string(resource), Renderer.VIEWS_FOLDER, string(action) * JSON_FILE_EXT));
        context = context, status = status, headers = headers, vars...)
end


function json(datafile::Genie.Renderer.FilePath; context::Module = @__MODULE__,
              status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders(), vars...) :: Genie.Renderer.HTTP.Response
  Genie.Renderer.WebRenderable(Genie.Renderer.render(MIME"application/json", datafile; context = context, vars...), :json, status, headers) |> Genie.Renderer.respond
end


function json(data::String; context::Module = @__MODULE__,
              status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders(), vars...) :: Genie.Renderer.HTTP.Response
  Genie.Renderer.WebRenderable(Genie.Renderer.render(MIME"application/json", data; context = context, vars...), :json, status, headers) |> Genie.Renderer.respond
end


function json(data::Any; status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders()) :: Genie.Renderer.HTTP.Response
  Genie.Renderer.WebRenderable(Genie.Renderer.render(MIME"application/json", data), :json, status, headers) |> Genie.Renderer.respond
end

function json(exception::JSONException; headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders()) :: Genie.Renderer.HTTP.Response
  Genie.Renderer.WebRenderable(Genie.Renderer.render(MIME"application/json", exception.message), :json, exception.status, headers) |> Genie.Renderer.respond
end


### === ###
### EXCEPTIONS ###


function Genie.Router.error(error_message::String, ::Type{MIME"application/json"}, ::Val{500}; error_info::String = "") :: HTTP.Response
  json(Dict("error" => "500 Internal Error - $error_message", "info" => error_info), status = 500)
end


function Genie.Router.error(error_message::String, ::Type{MIME"application/json"}, ::Val{404}; error_info::String = "") :: HTTP.Response
  json(Dict("error" => "404 Not Found - $error_message", "info" => error_info), status = 404)
end


function Genie.Router.error(error_code::Int, error_message::String, ::Type{MIME"application/json"}; error_info::String = "") :: HTTP.Response
  json(Dict("error" => "$error_code Error - $error_message", "info" => error_info), status = error_code)
end

end