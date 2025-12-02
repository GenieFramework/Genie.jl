module JSONParser

import JSON, OrderedCollections
import ..Util: package_version

DEFAULT_DICT_TYPE = @static if VersionNumber(package_version(JSON)) >= v"1-"
    JSON.Object{String, Any}
else
    OrderedCollections.OrderedDict{String, Any}
end

@inline typify(x) = x
typify(x::Number) = isinteger(x) && typemin(Int) ≤ x ≤ typemax(Int) ? Int(x) : x
typify!(x::Number) = isinteger(x) && typemin(Int) ≤ x ≤ typemax(Int) ? Int(x) : x

# Entry point for JSON objects
@inline function typify(d::AbstractDict{String, Any})
    typify!(deepcopy(d))   # copy so we don't mutate user data
end

# Entry point for heterogeneous vectors
@inline function typify(v::Vector)
    typify!(deepcopy(v))
end

function typify!(@nospecialize(v))
    if v isa AbstractDict{String, Any}
        for (k, val) in v
            if val isa Vector{Any} || val isa AbstractDict || val isa Vector{<:Number} || val isa Number
                v[k] = typify!(val)
            end
        end
    elseif v isa Vector{Any} || v isa Vector{<:Number}
        # Mutate recursively
        if Int <: eltype(v)
            for i in eachindex(v)
                x = v[i]
                if x isa Vector{Any} || x isa AbstractDict || x isa Vector{<:Number} || x isa Number
                    v[i] = typify!(x)
                end
            end
        else
            if all(isinteger, v)
                return convert(Vector{Int}, v)
            end
        end
        # Try to promote element types
        T = promote_type(union(map(typeof, v))...)
        if T != Any
            try
                return convert(Vector{T}, v)
            catch
            end
        end
    end
    return v
end

@static if VersionNumber(package_version(JSON)) >= v"1-"
    function parse(x, args...; dicttype = DEFAULT_DICT_TYPE, allownan = true, nan = "\"__nan__\"", inf = "\"__inf__\"", ninf = "\"__neginf__\"", kwargs...)
      JSON.parse(x, args...; dicttype, allownan, nan, inf, ninf, kwargs...) |> typify!
    end
    
    function json(x; allownan = true, nan = "\"__nan__\"", inf = "\"__inf__\"", ninf = "\"__neginf__\"", kwargs...)
        JSON.json(x; allownan = allownan, nan, inf, ninf, kwargs...)
    end
else
    # don't support allownan etc for older JSON versions, they are either not supported or behave differently (danger of interpreting "Infinity" as `Inf`)
    # caveat: parse(x, type::Type) is not supported for older JSON versions, it's defined here in case someone implements it in a custom way
    function parse(x, args...; dicttype = DEFAULT_DICT_TYPE, kwargs...)
      JSON.parse(x, args...; dicttype, kwargs...) |> typify!
    end
    
    function json(x; kwargs...)
        JSON.json(x; kwargs...)
    end
end

end
