using SearchLight

try
  SearchLight.Configuration.load()

  if SearchLight.config.db_config_settings["adapter"] !== nothing
    eval(Meta.parse("using SearchLight$(SearchLight.config.db_config_settings["adapter"])"))
    SearchLight.connect()

    @eval begin
      using Genie.Renderer.Json

      function Genie.Renderer.Json.JSON3.StructTypes.StructType(::Type{T}) where {T<:SearchLight.AbstractModel}
        Genie.Renderer.Json.JSON3.StructTypes.Struct()
      end

      function Genie.Renderer.Json.JSON3.StructTypes.StructType(::Type{SearchLight.DbId})
        Genie.Renderer.Json.JSON3.StructTypes.Struct()
      end
    end
  end
catch ex
  @error ex
end