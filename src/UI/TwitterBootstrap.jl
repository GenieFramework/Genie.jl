module TwitterBootstrap

module Layout

using Genie, Genie.Flax

function merge_attributes(elem_attrs::Vector{Pair{Symbol,String}}, attrs::Pair{Symbol,String}...) :: Dict{Symbol,String}
  attributes = Dict(attrs...)
  for (k,v) in elem_attrs
    attributes[k] = get!(attributes, k, "") * " $v" |> strip
  end

  attributes
end


function breakdowns_to_css_classes(elem::Union{Symbol,String}, breakdowns::Vector{Pair{Symbol,Union{Int,Symbol}}})
  classes = String["$elem"]

  for (k,v) in breakdowns
    breakdown = "$elem-"
    k != :any && (breakdown *= string(k) * "-")
    v != :any && (breakdown *= string(v) * "-")
    endswith(breakdown, "-") && (breakdown = breakdown[1:end-1])
    push!(classes, breakdown)
  end

  join(unique!(classes), " ")
end


function container(children::Function = ()->"", attrs::Pair{Symbol,String}...; fluid = false)
  Flax.div(children, merge_attributes([:class => fluid ? "container-fluid" : "container"], attrs...)...)
end
function container(attrs::Pair{Symbol,String}...; fluid = false)
  container(()->"", attrs..., fluid = fluid)
end


function row(children::Function = ()->"", attrs::Pair{Symbol,String}...; alignitems::Symbol = Symbol(""), justifycontent::Symbol = Symbol(""), nogutters::Bool = false)
  classes = String["row"]
  if alignitems != Symbol("")
    allowed_values = [:start, :center, :end]
    in(alignitems, allowed_values) || log("alignitems should be one of $(string(allowed_values))", :warn)
    push!(classes, "align-items-$alignitems")
  end
  if justifycontent != Symbol("")
    allowed_values = [:start, :center, :end, :around, :between]
    in(justifycontent, allowed_values) || log("alignitems should be one of $(string(allowed_values))", :warn)
    push!(classes, "align-items-$justifycontent")
  end
  nogutters && push!(classes, "no-gutters")
  Flax.div(children, merge_attributes([:class => join(unique!(classes), " ")], attrs...)...)
end
function row(attrs::Pair{Symbol,String}...; alignitems::Symbol = Symbol(""), justifycontent::Symbol = Symbol(""), nogutters::Bool = false)
  row(()->"", attrs..., alignitems = alignitems, justifycontent = justifycontent, nogutters = nogutters)
end


function col(children::Function = ()->"", attrs::Pair{Symbol,String}...; breakdowns::Vector{Pair{Symbol,Union{Int,Symbol}}} = Pair{Symbol,Union{Int,Symbol}}[], alignself::Symbol = Symbol(""))
  classes = String["col"]
  if alignself != Symbol("")
    allowed_values = [:start, :center, :end]
    in(alignself, allowed_values) || log("alignself should be one of $(string(allowed_values))", :warn)
    push!(classes, "align-self-$alignself")
  end
  push!(classes, breakdowns_to_css_classes("col", breakdowns))

  Flax.div(children, merge_attributes([:class => join(unique!(classes), " ")], attrs...)...)
end
function col(attrs::Pair{Symbol,String}...; breakdowns::Vector{Pair{Symbol,Union{Int,Symbol}}} = Pair{Symbol,Union{Int,Symbol}}[], alignself::Symbol = Symbol(""))
  col(()->"", attrs..., breakdowns = breakdowns, alignself = alignself)
end
function colbreak(attrs::Pair{Symbol,String}...)
  Flax.div(merge_attributes([:class => "w-100"], attrs...)...)
end


end # Layout

end
