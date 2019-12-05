module JSONRenderer

import Revise
import JSON
using Genie, Genie.Flax

const JSONParser = JSON
const JSON_FILE_EXT = ".json.jl"
const JSONString = String

export JSONString


function render(viewfile::Flax.FilePath; context::Module = @__MODULE__, vars...) :: Function
  Flax.registervars(vars...)
  Flax.injectvars(context)

  () -> (Base.include(context, string(viewfile)) |> JSONParser.json)
end


function render(data::String; context::Module = @__MODULE__, vars...) :: Function
  Flax.registervars(vars...)
  Flax.injectvars(context)

  () -> (Base.include_string(context, data) |> JSONParser.json)
end


function render(data) :: Function
  () -> JSONParser.json(data)
end

end