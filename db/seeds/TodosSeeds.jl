module TodosSeeds

using Genie, App, SearchLight

function random(quantity = 10)
  for i in 1:quantity
    Todos.random() |> SearchLight.save!
  end
end

end
