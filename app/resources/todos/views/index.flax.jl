using Flax, Helpers

(vars) -> begin
  d(:class => "row") do
    ul(:class => "list-group") do
    [
      mapreduce(*, vars[:todos]) do (todo)
        li(:class => "list-group-item") do
          todo.title
        end
      end
    ]
    end
  end
end
