module Validation
using Genie, SearchLight, App

#
# validation rules
#

function not_empty{T<:AbstractModel}(field::Symbol, m::T) :: Bool
  error_message = "$field should be not empty"
  getfield(m, field) |> isempty && push_error!(m, field, :not_empty, error_message) && return false

  true
end

function min_length{T<:AbstractModel}(field::Symbol, m::T, args::Vararg{Any}) :: Bool
  field_length = getfield(m, field) |> length
  error_message = "$field should be at least $(args[1]) chars long and it's only $field_length"
  field_length < args[1] && push_error!(m, field, :min_length, error_message) && return false

  true
end

#
# errors manipulation
#

function push_error!{T<:AbstractModel}(m::T, field::Symbol, error::Symbol, error_message::AbstractString) :: Bool
  push!(errors!!(m), (field, error, error_message))

  true # this must be bool cause it's used for chaining Bool values
end

function clear_errors!{T<:AbstractModel}(m::T) :: Void
  errors!!(m) |> empty!

  nothing
end

#
# validation logic
#

function validate!{T<:AbstractModel}(m::T) :: Bool
  ! has_validator(m) && return true
  
  clear_errors!(m)

  for r in rules!!(m)
    field = r[1]
    rule = r[2]
    args = length(r) == 3 ? r[3] : ()
    rule(field, m, args...)
  end

  is_valid(m)
end

function rules!!{T<:AbstractModel}(m::T) :: Vector{Tuple{Symbol,Function,Vararg{Any}}}
  validator!!(m).rules # rules::Vector{Tuple{Symbol,Symbol,Vararg{Any}}} -- field,method,args
end

function rules{T<:AbstractModel}(m::T) :: Nullable{Vector{Tuple{Symbol,Function,Vararg{Any}}}}
  v = validator(m)
  isnull(v) ? Nullable{Vector{Tuple{Symbol,Symbol,Vararg{Any}}}}() : Nullable{Vector{Tuple{Symbol,Symbol,Vararg{Any}}}}(Base.get(v).errors)
end

function errors!!{T<:AbstractModel}(m::T) :: Vector{Tuple{Symbol,Symbol,String}}
  validator!!(m).errors
end

function errors{T<:AbstractModel}(m::T) :: Nullable{Vector{Tuple{Symbol,Symbol,String}}}
  v = validator(m)
  isnull(v) ? Nullable{Vector{Tuple{Symbol,Symbol,String}}}() : Nullable{Vector{Tuple{Symbol,Symbol,String}}}(v.errors)
end

function validator!!{T<:AbstractModel}(m::T) :: ModelValidator
  m.validator
end

function validator{T<:AbstractModel}(m::T) :: Nullable{ModelValidator}
  has_validator(m) ? Nullable{ModelValidator}(m.validator) : Nullable{ModelValidator}()
end

function has_validator{T<:AbstractModel}(m::T) :: Bool
  has_field(m, :validator)
end

function has_errors{T<:AbstractModel}(m::T) :: Bool
  ! isempty( errors!!(m) )
end

function has_errors_for{T<:AbstractModel}(m::T, field::Symbol) :: Bool
  ! isempty(errors_for(m, field))
end

function is_valid{T<:AbstractModel}(m::T) :: Bool
  ! has_errors(m)
end

function errors_for{T<:AbstractModel}(m::T, field::Symbol) :: Vector{Tuple{Symbol,Symbol,AbstractString}}
  result = Tuple{Symbol,Symbol,AbstractString}[]
  for err in errors!!(m)
    err[1] == field && push!(result, err)
  end

  result
end

function errors_messages_for{T<:AbstractModel}(m::T, field::Symbol) :: Vector{AbstractString}
  result = AbstractString[]
  for err in errors_for(m, field)
    push!(result, err[3])
  end

  result
end

function errors_to_string{T<:AbstractModel}(m::T, field::Symbol, separator = "\n"; upper_case_first = false) :: String
  join( map(x -> upper_case_first ? ucfirst(x) : x, errors_messages_for(m, field)), separator)
end

end
