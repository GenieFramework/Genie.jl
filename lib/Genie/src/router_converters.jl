import Base.convert

convert(::Type{Int}, s::AbstractString) = parse(Int, s)

