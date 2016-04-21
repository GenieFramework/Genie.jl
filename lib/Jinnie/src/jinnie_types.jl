import Base.string
import Base.print
import Base.show

export JinnieType

abstract JinnieType
string{T<:JinnieType}(io::IO, t::T) = jinnietype_to_string(t)
print{T<:JinnieType}(io::IO, t::T) = print(io, jinnietype_to_print(t))
show{T<:JinnieType}(io::IO, t::T) = print(io, jinnietype_to_print(t))

function jinnietype_to_string{T<:JinnieType}(m::T)
  output = "$(typeof(m)) <: $(super(typeof(m)))" * "\n"
  for f in fieldnames(m)
    value = getfield(m, Symbol(f))
    output = output * "  + $f \t $(value) \n"
  end
  
  output
end

function jinnietype_to_print{T<:JinnieType}(m::T)
  output = "\n" * "$(typeof(m))" * "\n"
  output *= string(Millboard.table(Jinnie.Model.to_string_dict(m))) * "\n"
  
  output
end

function to_dict(m::Any) 
  [string(f) => getfield(m, Symbol(f)) for f in fieldnames(m)]
end

function to_string_dict(m::Any; all_output::Bool = false) 
  to_string_dict(m, fieldnames(m), all_output = all_output)
end
function to_string_dict(m::Any, fields::Array{Symbol,1}; all_output::Bool = false)
  output_length = all_output ? 100_000_000 : Jinnie.config.output_length
  response = Dict{AbstractString, AbstractString}()
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