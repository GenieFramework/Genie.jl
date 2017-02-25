el(
  todos = [
    include(joinpath("partials", "item.json.jl"))(t) for t = @vars(:todos)
  ]
)
