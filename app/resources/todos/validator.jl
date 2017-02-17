module TodoValidator

using App, SearchLight, Validation

function not_empty{T<:AbstractModel}(field::Symbol, m::T, args::Any...)::Bool
  isempty( getfield(m, field) ) && return false
  true
end

end
