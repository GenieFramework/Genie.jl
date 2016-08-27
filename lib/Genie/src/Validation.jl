module Validation
using Genie, Model

#
# validation rules
#

function not_empty{T<:AbstractModel}(field::Symbol, m::T, args::Vararg{Any})
  error_message = "$field should be not empty"
  getfield(m, field) |> isempty && push_error!(m, field, :not_empty, error_message) && return false

  true
end

function min_length{T<:AbstractModel}(field::Symbol, m::T, args::Vararg{Any})
  field_length = getfield(m, field) |> length
  error_message = "$field should be at least $(args[1]) chars long and it's only $field_length"
  field_length < args[1] && push_error!(m, field, :min_length, error_message) && return false

  true
end

#
# errors manipulation
#

function push_error!{T<:AbstractModel}(m::T, field::Symbol, error::Symbol, error_message::AbstractString)
  push!(errors(m), (field, error, error_message))

  true
end

function clear_errors!{T<:AbstractModel}(m::T)
  errors(m) |> empty!
end

#
# validation logic
#

function validate!{T<:AbstractModel}(m::T)
  clear_errors!(m)

  for r in rules(m)
    field = r[1]
    rule = r[2]
    args = length(r) == 3 ? r[3] : ()
    rule(field, m, args...)
  end

  is_valid(m)
end

function rules{T<:AbstractModel}(m::T)
  validator(m).rules # rules::Vector{Tuple{Symbol,Symbol,Vararg{Any}}} -- field,method,args
end

function errors{T<:AbstractModel}(m::T)
  validator(m).errors
end

function validator{T<:AbstractModel}(m::T)
  m._validator
end

function has_errors{T<:AbstractModel}(m::T)
  ! isempty( errors(m) )
end

function is_valid{T<:AbstractModel}(m::T)
  ! has_errors(m)
end

end