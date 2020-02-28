Base.@kwdef struct option
  disabled::Bool = false
  selected::Bool = false
  value::String = ""
  text::String = value
end


function Base.string(o::option) :: HTMLString
  attributes = String[]

  o.disabled && push!(attributes, "disabled")
  o.selected && push!(attributes, "selected")
  push!(attributes, "value=\"$(o.value)\"")

  "<option $(join(attributes, " "))>$(o.text)</option>"
end


function select(options::Vector{option}, args...; attrs...) :: HTMLString
  children = String[]

  for o in options
    push!(children, string(o))
  end

  normal_element(children, "select", [args...], Pair{Symbol,Any}[attrs...])
end


function optgroup(options::Vector{option}, args...; attrs...) :: HTMLString
  children = String[]

  for o in options
    push!(children, string(o))
  end

  normal_element(children, "optgroup", [args...], Pair{Symbol,Any}[attrs...])
end