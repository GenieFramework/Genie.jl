module JSONRenderer

import Revise
import JSON3, FilePaths
using Genie
using ..Flax

const JSONParser = JSON3
const JSON_FILE_EXT = ".json.jl"
const JSONString = String

export JSONString


function render(viewfile::FilePaths.PosixPath; context::Module = @__MODULE__, vars...) :: Function
  Flax.registervars(vars...)

  () -> (Base.include(context, string(viewfile)) |> JSONParser.write)
end


function render(data::String; context::Module = @__MODULE__, vars...) :: Function
  Flax.registervars(vars...)

  () -> (Base.include_string(context, data) |> JSONParser.write)
end


function render(data) :: Function
  () -> JSONParser.write(data)
end

end