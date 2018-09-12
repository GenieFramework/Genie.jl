module TwitterBootstrap

module Layout

using Genie, Genie.Flax

function merge_attributes(elem_attrs::Vector{Pair{Symbol,Any}}, attrs::Pair{Symbol,Any}...) :: Dict{Symbol,Any}
  attributes = Dict(attrs...)

  for (k,v) in attributes
    if startswith(string(k), "data_")
      attributes[Symbol(replace(string(k), r"^data_" => "data-"))] = get!(attributes, k, "")
      delete!(attributes, k)
    end
  end

  for (k,v) in elem_attrs
    attributes[k] = get!(attributes, k, "") * " $v" |> strip
  end

  attributes
end


function breakdowns_to_css_classes(elem::Union{Symbol,String}, breakdowns::Vector{Pair{Symbol,Union{Int,Symbol,String}}})
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


function container(children::Union{Function,String,Vector{String}} = ""; fluid::Bool = false, attrs...)
  Flax.div(children; merge_attributes(Pair{Symbol,Any}[:class => fluid ? "container-fluid" : "container"], Pair{Symbol,Any}[attrs...]...)...)
end


function row(children::Union{Function,String,Vector{String}} = ""; alignitems::Union{String,Symbol} = "", justifycontent::Union{String,Symbol} = "", nogutters::Bool = false, attrs...)
  classes = String["row"]
  alignitems = string(alignitems)

  if alignitems != ""
    allowed_values = ["start", "center", "end"]
    in(alignitems, allowed_values) || log("alignitems should be one of $allowed_values", :warn)
    push!(classes, "align-items-$alignitems")
  end

  if justifycontent != ""
    allowed_values = ["start", "center", "end", "around", "between"]
    in(justifycontent, allowed_values) || log("alignitems should be one of $allowed_values", :warn)
    push!(classes, "align-items-$justifycontent")
  end

  nogutters && push!(classes, "no-gutters")

  Flax.div(children; merge_attributes(Pair{Symbol,Any}[:class => join(unique!(classes), " ")], Pair{Symbol,Any}[attrs...]...)...)
end


function col(children::Union{Function,String,Vector{String}} = "";
              breakdowns::Vector{Pair{Symbol,Union{Int,Symbol,String}}} = Pair{Symbol,Union{Int,Symbol,String}}[],
              alignself::Union{String,Symbol} = "", attrs...)
  classes = String["col"]

  if alignself != ""
    allowed_values = ["start", "center", "end"]
    in(alignself, allowed_values) || log("alignself should be one of $allowed_values)", :warn)
    push!(classes, "align-self-$alignself")
  end

  push!(classes, breakdowns_to_css_classes("col", breakdowns))

  Flax.div(children; merge_attributes(Pair{Symbol,Any}[:class => join(unique!(classes), " ")], Pair{Symbol,Any}[attrs...]...)...)
end


function colbreak(attrs...)
  Flax.div(; merge_attributes(Pair{Symbol,Any}[:class => "w-100"], Pair{Symbol,Any}[attrs...]...)...)
end


end # Layout

end
