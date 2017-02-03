using Flax

function(params::Dict)
  html() do
  [
    head() do
      title() do
        "Genie"
      end
    end
    body() do
    [
        h2() do
          "Welcomeeee"
        end
        d() do
          params[:yield!!] |> uppercase
        end
        br()

        include("app/layouts/shared/footer.flax.jl")(params)
    ] end
  ] end |> Flax.doc
end
