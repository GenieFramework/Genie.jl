function form(f::Function, args...; attrs...) :: HTMLString
  normal_element(f, "form", [args...], attr(attrs...))
end

function form(children::Union{String,Vector{String}} = "", args...; attrs...) :: HTMLString
  normal_element(children, "form", [args...], attr(attrs...))
end

function attr(attrs...)
  attrs = Pair{Symbol,Any}[attrs...]

  for p in attrs
    p[1] == :enctype && return attrs
  end

  push!(attrs, :enctype => "multipart/form-data")
end