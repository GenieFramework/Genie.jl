import Base.string
import Base.print
import Base.show
import Millboard



"""
$TYPEDSIGNATURES

Creates a `Dict` using the fields and the values of `m`.
"""
function to_dict(m::Any) :: Dict{String,Any}
  Dict(string(f) => getfield(m, Symbol(f)) for f in fieldnames(typeof(m)))
end
"""
$TYPEDSIGNATURES
"""
function to_string_dict(m::Any; all_output::Bool = false) :: Dict{String,String}
  to_string_dict(m, fieldnames(m), all_output = all_output)
end
"""
$TYPEDSIGNATURES
"""
function to_string_dict(m::Any, fields::Array{Symbol,1}; all_output::Bool = false) :: Dict{String,String}
  response = Dict{String,String}()
  for f in fields
    response[string(f)] = string(getfield(m, Symbol(f)))
  end

  response
end
