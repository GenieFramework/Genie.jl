---
numbers: [1, 1, 2, 3, 5, 8, 13]
---

# There are $(length(numbers))

$(
  for_each(numbers) do number
    " -> $number
    "
  end
)