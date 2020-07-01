# There are $(length(numbers))

$(
  @foreach(numbers) do number
    " -> $number
    "
  end
)