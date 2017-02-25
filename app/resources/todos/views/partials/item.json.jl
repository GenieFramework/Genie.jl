(t::Todo) -> begin
el(
  id = t.id |> Base.get, 
  todo = t.title,
  completed = t.completed
)
end
