import Base.convert

convert(::Type{Int}, s::String) = parse(Int, s)
