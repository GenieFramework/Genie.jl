import Base.string
import Base.print
import Base.show

export GenieType, GenieController, Controller

abstract type GenieType end
string(io::IO, t::T) where {T<:GenieType} = "$(typeof(t)) <: $(super(typeof(t)))"
print(io::IO, t::T) where {T<:GenieType} = print(io, "$(typeof(t)) <: $(super(typeof(t)))")
show(io::IO, t::T) where {T<:GenieType} = print(io, genietype_to_print(t))

mutable struct GenieController <: GenieType
end

const Controller = GenieController

mutable struct GenieChannel <: GenieType
end

# const Channel = GenieChannel

using Millboard


"""
    genietype_to_print{T<:GenieType}(m::T) :: String

Pretty printing of Genie types.
"""
function genietype_to_print(m::T) :: String where {T<:GenieType}
  output = "\n" * "$(typeof(m))" * "\n"
  output *= string(config.log_formatted ? Millboard.table(to_string_dict(m)) : to_string_dict(m) ) * "\n"

  output
end


"""
    to_string_dict{T<:GenieType}(m::T; all_fields::Bool = false, all_output::Bool = false) :: Dict{String,String}

Converts a type `m` to a `Dict{String,String}`. Orginal types of the fields values are converted to strings.
If `all_fields` is `true`, all fields are included; otherwise just the fields corresponding to database columns.
"""
function to_string_dict(m::T; all_fields::Bool = false, all_output::Bool = false) :: Dict{String,String} where {T<:GenieType}
  fields = all_fields ? fieldnames(m) : persistable_fields(m)
  response = Dict{String,String}()
  for f in fields
    response[string(f)] = string(getfield(m, Symbol(f)))
  end

  response
end


"""
    to_dict(m::Any) :: Dict{String,Any}
    to_string_dict(m::Any; all_output::Bool = false) :: Dict{String,String}
    to_string_dict(m::Any, fields::Array{Symbol,1}; all_output::Bool = false) :: Dict{String,String}

Creates a `Dict` using the fields and the values of `m`.
"""
function to_dict(m::Any) :: Dict{String,Any}
  Dict(string(f) => getfield(m, Symbol(f)) for f in fieldnames(typeof(m)))
end
function to_string_dict(m::Any; all_output::Bool = false) :: Dict{String,String}
  to_string_dict(m, fieldnames(m), all_output = all_output)
end
function to_string_dict(m::Any, fields::Array{Symbol,1}; all_output::Bool = false) :: Dict{String,String}
  response = Dict{String,String}()
  for f in fields
    response[string(f)] = string(getfield(m, Symbol(f)))
  end

  response
end
