using Genie, Genie.Router, Genie.Renderer.Json

Genie.config.run_as_server = true
Genie.config.cors_allowed_origins = ["*"]

route("/random", method=POST) do
  dim = parse(Int, get(@params, :dim, "2"))
  num = parse(Int, get(@params, :num, "3"))

  (:random => rand(dim,num)) |> json
end

up(; open_browser = false)