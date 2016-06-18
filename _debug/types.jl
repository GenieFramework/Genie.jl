abstract Model 

type ModelA <: Model 
  class::AbstractString
  ModelA() = new("ModelA")
end

type ModelB <: Model
  class::AbstractString
  ModelB() = new("ModelB")
end

function get_class{T<:Model}(m::T)
  return m.class
end

function get_class(m)
  if typeof(m()) <: Model
    return m().class
  else
    error("$m is not a subtype of Model")
  end
end