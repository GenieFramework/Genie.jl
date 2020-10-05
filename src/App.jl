"""
App level functionality -- loading and managing app-wide components like configs, models, initializers, etc.
"""
module App

import Genie

const ASSET_FINGERPRINT = ""


### PRIVATE ###


"""
    bootstrap(context::Union{Module,Nothing} = nothing) :: Nothing

Kickstarts the loading of a Genie app by loading the environment settings.
"""
function bootstrap(context::Union{Module,Nothing} = Genie.default_context(context)) :: Nothing
  if haskey(ENV, "GENIE_ENV") && isfile(joinpath(Genie.config.path_env, ENV["GENIE_ENV"] * ".jl"))
    isfile(joinpath(Genie.config.path_env, Genie.GLOBAL_ENV_FILE_NAME)) && Base.include(context, joinpath(Genie.config.path_env, Genie.GLOBAL_ENV_FILE_NAME))
    isfile(joinpath(Genie.config.path_env, ENV["GENIE_ENV"] * ".jl")) && Base.include(context, joinpath(Genie.config.path_env, ENV["GENIE_ENV"] * ".jl"))
  else
    ENV["GENIE_ENV"] = Genie.Configuration.DEV
    Core.eval(context, Meta.parse("const config = Genie.Configuration.Settings(app_env = Genie.Configuration.DEV)"))
  end

  for f in fieldnames(typeof(context.config))
    setfield!(Genie.config, f, getfield(context.config, f))
  end

  printstyled("""

   _____         _         ____  _
  |   __|___ ___|_|___    |_  _|| |
  |  |  | -_|   | | -_| _  _||  | |_
  |_____|___|_|_|_|___||_||__|  |___|

                           ❤️ v1.5.0

  """, color = :red, bold = true)

  printstyled("|> Web: https://genieframework.com\n", color = :light_black, bold = true)
  printstyled("|> GitHub: https://github.com/genieframework/Genie.jl\n", color = :light_black, bold = true)
  printstyled("|> Docs: https://genieframework.github.io/Genie.jl/dev\n", color = :light_black, bold = true)
  printstyled("|> Gitter: https://gitter.im/essenciary/Genie.jl\n", color = :light_black, bold = true)
  printstyled("|> Twitter: https://twitter.com/GenieMVC\n\n", color = :light_black, bold = true)

  printstyled("Genie v$(Genie.Configuration.GENIE_VERSION)\n", color = :green, bold = true)
  printstyled("Made with Julia and ❤️\n", color = :light_green, bold = true)
  printstyled("Active env => $(ENV["GENIE_ENV"] |> uppercase)\n\n", color = :light_blue, bold = true)

  nothing
end

end # module App