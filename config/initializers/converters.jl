import Base.convert

convert(::Type{Int},    v::SubString{String}) = parse(Int, v)
