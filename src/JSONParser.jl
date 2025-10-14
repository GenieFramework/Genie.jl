module JSONParser

import JSON, OrderedCollections

@inline typify(x) = x

# Entry point for JSON objects
@inline function typify(d::AbstractDict{String, Any})
    typify!(deepcopy(d))   # copy so we don't mutate user data
end

# Entry point for heterogeneous vectors
@inline function typify(v::Vector{Any})
    typify!(deepcopy(v))
end

function typify!(@nospecialize(v))
    if v isa JSON.Object{String, Any}
        for (k, val) in v
            if val isa Vector{Any} || val isa AbstractDict
                v[k] = typify!(val)
            end
        end
        return v

    elseif v isa Vector{Any} || v isa Vector{Float64}
        # Mutate recursively
        for i in eachindex(v)
            x = v[i]
            if x isa Vector{Any} || x isa AbstractDict
                v[i] = typify!(x)
            else
                if x isa Float64 && isinteger(x) && typemin(Int) ≤ x ≤ typemax(Int)
                    v[i] = Int(x)
                end
            end
        end
        # Try to promote element types
        T = promote_type(map(typeof, v)...)
        if T != Any
            try
                return convert(Vector{T}, v)
            catch
                return v
            end
        else
            return v
        end
    else
        return v
    end
end

JSON.lower(p::Pair) = JSON.Object(Symbol(p.first) => p.second)
JSON.lower(::JSON.JSONStyle, pp::AbstractVector{<:Pair}) = JSON.Object(pp)

function parse(x, args...; dicttype = Dict{String, Any}, allownan = true, nan = "__nan__", inf = "\"__inf__\"", ninf = "\"__neginf__\"", kwargs...)
  JSON.parse(x, args...; allownan, nan, inf, ninf, kwargs...) |> typify!
end

function parse(x::AbstractString, args...; allownan = true, nan = "__nan__", inf = "\"__inf__\"", ninf = "\"__neginf__\"", kwargs...)
    parse(codeunits(x), args...; allownan, nan, inf, ninf, kwargs...)
end

function json(x; allownan = true, nan = "__nan__", inf = "\"__inf__\"", ninf = "\"__neginf__\"", kwargs...)
    JSON.json(x; allownan = allownan, nan, inf, ninf, kwargs...)
end

end
