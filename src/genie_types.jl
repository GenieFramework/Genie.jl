import Base.string
import Base.print
import Base.show

export GenieType, GenieController, Controller

abstract type GenieType end
string{T<:GenieType}(io::IO, t::T) = "$(typeof(t)) <: $(super(typeof(t)))"
print{T<:GenieType}(io::IO, t::T) = print(io, "$(typeof(t)) <: $(super(typeof(t)))")
show{T<:GenieType}(io::IO, t::T) = print(io, genietype_to_print(t))

type GenieController <: GenieType
end

const Controller = GenieController

type GenieChannel <: GenieType
end

const Channel = GenieChannel


"""
    genietype_to_print{T<:GenieType}(m::T) :: String

Pretty printing of Genie types.
"""
function genietype_to_print{T<:GenieType}(m::T) :: String
  output = "\n" * "$(typeof(m))" * "\n"
  output *= string(config.log_formatted ? Millboard.table(to_string_dict(m)) : to_string_dict(m) ) * "\n"

  output
end


"""
    to_string_dict{T<:GenieType}(m::T; all_fields::Bool = false, all_output::Bool = false) :: Dict{String,String}

Converts a type `m` to a `Dict{String,String}`. Orginal types of the fields values are converted to strings.
If `all_fields` is `true`, all fields are included; otherwise just the fields corresponding to database columns.
If `all_output` is `false` the values are truncated if longer than `output_length`.
"""
function to_string_dict{T<:GenieType}(m::T; all_fields::Bool = false, all_output::Bool = false) :: Dict{String,String}
  fields = all_fields ? fieldnames(m) : persistable_fields(m)
  output_length = all_output ? 100_000_000 : config.output_length
  response = Dict{String,String}()
  for f in fields
    key = string(f)
    value = string(getfield(m, Symbol(f)))
    if length(value) > output_length
      value = value[1:output_length] * "..."
    end
    response[key] = value
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
  Dict(string(f) => getfield(m, Symbol(f)) for f in fieldnames(m))
end
function to_string_dict(m::Any; all_output::Bool = false) :: Dict{String,String}
  to_string_dict(m, fieldnames(m), all_output = all_output)
end
function to_string_dict(m::Any, fields::Array{Symbol,1}; all_output::Bool = false) :: Dict{String,String}
  output_length = all_output ? 100_000_000 : config.output_length
  response = Dict{String,String}()
  for f in fields
    key = string(f)
    value = string(getfield(m, Symbol(f)))
    if length(value) > output_length
      value = value[1:output_length] * "..."
    end
    response[key] = string(value)
  end

  response
end
