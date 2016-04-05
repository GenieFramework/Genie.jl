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
    value = getfield(m, symbol(f))
    output = output * "  + $f \t $(value) \n"
  end
  
  output
end

function jinnietype_to_print{T<:JinnieType}(m::T)
  output = "\n" * "$(typeof(m))" * "\n"
  output *= string(Millboard.table(Jinnie.Model.to_string_dict(m))) * "\n"
  
  output
end

function to_dict(m::Any; all_fields = false) 
  [string(f) => getfield(m, Symbol(f)) for f in fieldnames(m)]
end

function to_string_dict(m::Any; all_fields = false) 
  [string(f) => string(getfield(m, Symbol(f))) for f in fieldnames(m)]
end