module DatabaseSeeding

push!(LOAD_PATH, abspath(joinpath("db", "seeds")))

export random_seeder


"""
    random_seeder(m::Module, quantity = 10, save = false)

Generic random database seeder. `m` must expose a `random()` function which returns a SearchLight instance.
If `save` the data will be persisted to the database, as configured for the current environment. 
"""
function random_seeder(m::Module, quantity = 10, save = false)
  @eval :(using $m)

  seeds = []
  for i in 1:quantity
    item = m.random()
    push!(seeds, item)

    save && SearchLight.save!(item)
  end

  seeds
end

end
