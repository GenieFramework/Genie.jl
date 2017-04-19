module DatabaseSeeding

push!(LOAD_PATH, abspath(joinpath("db", "seeds")))

export random_seeder

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
