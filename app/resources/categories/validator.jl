module CategoryValidator
using App, SearchLight, Validation

function not_empty{T<:AbstractModel}(field::Symbol, m::T, args::Vararg{Any})::Bool
  isempty( getfield(m, field) ) && return false
  true
end

end
