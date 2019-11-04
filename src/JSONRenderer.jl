module JSONRenderer

import Revise
import JSON
using Genie
using ..Flax

const JSON_FILE_EXT = ".json.jl"

const JSONString = String

export JSONString


"""
    render(resource::Union{Symbol,String}, action::Union{Symbol,String}; context::Module = @__MODULE__, vars...) :: Function

Renders data as JSON
"""
@inline function render(resource::Union{Symbol,String}, action::Union{Symbol,String}; context::Module = @__MODULE__, vars...) :: Function
  Flax.registervars(vars...)

    () -> (Base.include(context, joinpath(Genie.RESOURCES_PATH, string(resource), Genie.VIEWS_FOLDER, string(action) * JSON_FILE_EXT)) |> JSON.json)
end

end