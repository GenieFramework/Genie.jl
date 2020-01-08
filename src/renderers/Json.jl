module Json

import Revise
import JSON
using Genie, Genie.Renderer

const JSONParser = JSON
const JSON_FILE_EXT = ".json.jl"
const JSONString = String

export JSONString, json


function render(viewfile::Genie.Renderer.FilePath; context::Module = @__MODULE__, vars...) :: Function
  Genie.Renderer.registervars(vars...)
  Genie.Renderer.injectvars(context)

  () -> (Base.include(context, string(viewfile)) |> JSONParser.json)
end


function render(data::String; context::Module = @__MODULE__, vars...) :: Function
  Genie.Renderer.registervars(vars...)
  Genie.Renderer.injectvars(context)

  try
    () -> (Base.include_string(context, data) |> JSONParser.json)
  catch
    () -> JSONParser.json(data)
  end
end


function render(data) :: Function
  () -> JSONParser.json(data)
end


function Genie.Renderer.render(::Type{MIME"application/json"}, datafile::Genie.Renderer.FilePath; context::Module = @__MODULE__, vars...) :: Genie.Renderer.WebRenderable
  Genie.Renderer.WebRenderable(Base.invokelatest(render(datafile; context = context, vars...))::String, :json)
end


function Genie.Renderer.render(::Type{MIME"application/json"}, data::String; context::Module = @__MODULE__, vars...) :: Genie.Renderer.WebRenderable
  Genie.Renderer.WebRenderable(Base.invokelatest(render(data; context = context, vars...))::String, :json)
end


function Genie.Renderer.render(::Type{MIME"application/json"}, data::Any) :: Genie.Renderer.WebRenderable
  Genie.Renderer.WebRenderable(Base.invokelatest(render(data))::String, :json)
end


"""
"""
function json(resource::Genie.Renderer.ResourcePath, action::Genie.Renderer.ResourcePath; context::Module = @__MODULE__,
              status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders(), vars...) :: Genie.Renderer.HTTP.Response
  json(Path(joinpath(Genie.config.path_resources, string(resource), VIEWS_FOLDER, string(action) * JSON_FILE_EXT));
        context = context, status = status, headers = headers, vars...)
end


"""
"""
function json(datafile::Genie.Renderer.FilePath; context::Module = @__MODULE__,
              status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders(), vars...) :: Genie.Renderer.HTTP.Response
  Genie.Renderer.WebRenderable(Genie.Renderer.render(MIME"application/json", datafile; context = context, vars...), :json, status, headers) |> Genie.Renderer.respond
end


"""
"""
function json(data::String; context::Module = @__MODULE__,
              status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders(), vars...) :: Genie.Renderer.HTTP.Response
  Genie.Renderer.WebRenderable(Genie.Renderer.render(MIME"application/json", data; context = context, vars...), :json, status, headers) |> Genie.Renderer.respond
end


"""
"""
function json(data; status::Int = 200, headers::Genie.Renderer.HTTPHeaders = Genie.Renderer.HTTPHeaders()) :: Genie.Renderer.HTTP.Response
  Genie.Renderer.WebRenderable(Genie.Renderer.render(MIME"application/json", data), :json, status, headers) |> Genie.Renderer.respond
end

end