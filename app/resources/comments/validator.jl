module CommentValidator
using App, SearchLight, Validation

function not_empty{T<:AbstractModel}(::Symbol, m::T, args::Vararg{Any})::Bool
  isempty(m.some_property) && return false
  true
end

end
