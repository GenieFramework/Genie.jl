module TodoValidator

using App, SearchLight, Validation

function not_empty{T<:AbstractModel}(::Symbol, m::T, args::Any...)::Bool
  isempty(m.some_property) && return false
  true
end

end
