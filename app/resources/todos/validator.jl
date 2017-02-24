module TodoValidator

using App, SearchLight, Validation

function not_empty{T<:AbstractModel}(field::Symbol, m::T, args::Any...) :: ValidationStatus
  if isempty(getfield(m, field))
    false, :not_empty, "should be not empty"
  else
    true, :not_empty, ""
  end
end

end
