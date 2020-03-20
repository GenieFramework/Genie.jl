Base.@kwdef struct Option
  disabled::Bool = false
  selected::Bool = false
  value::String = ""
  text::String = value
end

function option(disabled::Bool, selected::Bool, value::String, text::String)
  Option(; disabled = disabled, selected = selected, value = value, text = text)
end


function Base.string(o::Option) :: HTMLString
  attributes = String[]

  o.disabled && push!(attributes, "disabled")
  o.selected && push!(attributes, "selected")
  push!(attributes, "value=\"$(o.value)\"")

  "<option $(join(attributes, " "))>$(o.text)</option>"
end


function select(options::Vector{Option}, args...; attrs...) :: HTMLString
  children = String[]

  for o in options
    push!(children, string(o))
  end

  normal_element(children, "select", [args...], Pair{Symbol,Any}[attrs...])
end


function select(options::Vector, args...; attrs...) :: HTMLString
  select([option(o) for o in options], args...; attrs...)
end


function select(options::Tuple, args...; attrs...) :: HTMLString
  select([option(o) for o in [options...]], args...; attrs...)
end


function optgroup(options::Vector{Option}, args...; attrs...) :: HTMLString
  children = String[]

  for o in options
    push!(children, string(o))
  end

  normal_element(children, "optgroup", [args...], Pair{Symbol,Any}[attrs...])
end