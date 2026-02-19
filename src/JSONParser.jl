module JSONParser

import JSON, OrderedCollections
import ..Util: package_version

const DEFAULT_DICT_TYPE = @static if isdefined(JSON, :Object)
    JSON.Object{String, Any}
else
    OrderedCollections.OrderedDict{String, Any}
end

const UNDEFINED_PLACEHOLDER = Ref{String}("__undefined__")
const UNDEFINED_REPLACEMENT = Ref{Any}(nothing)
const UNDEFINED_TYPE = Ref{DataType}(typeof(UNDEFINED_REPLACEMENT[]))

function set_undefined_replacement(x)
    UNDEFINED_REPLACEMENT[] = x
    UNDEFINED_TYPE[] = typeof(x)
    nothing
end

@static if isdefined(JSON, :StructUtils)
    JSON.StructUtils.lowerkey(::JSON.JSONWriteStyle, x::Module) = string(x)
end

@inline typify(x) = x
typify(x::String) = x == UNDEFINED_PLACEHOLDER[] ? UNDEFINED_REPLACEMENT[] : x
typify(x::Number) = isinteger(x) && !isa(x, Bool) && typemin(Int) ≤ x ≤ typemax(Int) ? Int(x) : x

# Entry point for JSON objects
@inline function typify(d::AbstractDict{<:Any, Any})
    typify!(deepcopy(d))   # copy so we don't mutate user data
end

# Entry point for heterogeneous vectors
@inline function typify(v::Vector)
    typify!(deepcopy(v))
end

function typify!(@nospecialize(v))
    v isa Number && return isinteger(v) && !isa(v, Bool) && typemin(Int) ≤ v ≤ typemax(Int) ? Int(v) : v

    v == UNDEFINED_PLACEHOLDER[] && return UNDEFINED_REPLACEMENT[]
    
    if v isa AbstractDict{<:Any, Any}
        for (k, val) in v
            if val == UNDEFINED_PLACEHOLDER[]
                v[k] = UNDEFINED_REPLACEMENT[]
            elseif val isa Vector{Any} || val isa AbstractDict || val isa Vector{<:Number} || val isa Number || val isa Vector{<:AbstractString}
                v[k] = typify!(val)
            end
        end
    elseif v isa Vector{Any} || v isa Vector{<:Number} || v isa Vector{<:AbstractString}
        # Mutate recursively
        for i in eachindex(v)
            x = v[i]
            if x == UNDEFINED_PLACEHOLDER[]
                if ! (UNDEFINED_TYPE[] <: eltype(v))
                    v = Vector{Any}(v)
                end
                v[i] = UNDEFINED_REPLACEMENT[]
            elseif x isa Vector{Any} || x isa AbstractDict || x isa Vector{<:Number} || x isa Number || x isa Vector{<:AbstractString}
                v[i] = typify!(x)
            end
        end

        # if all are Integer and not a single Boolean, return a Vector{Int}
        if all(Base.Fix2(isa, Number), v) && all(isinteger, v) && !any(isa.(v, Bool))
            return convert(Vector{Int}, v)
        end
        # Try to promote element types
        T = any(isa.(v, Bool)) ? Any : promote_type(union(map(typeof, v))...)
        # don't convert to promotetype if T is Any or UNDEFINED_TYPE
        if T !== Any && (T !== UNDEFINED_TYPE[] || any(UNDEFINED_REPLACEMENT[] .!= v))
            try
                v = convert(Vector{T}, v)
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

    # Helper to convert non-serializable types, as JSON v0.21 throws on type `Module`
    sanitize_for_json(x::Module) = string(x)
    sanitize_for_json(x::Pair) = x.first => sanitize_for_json(x.second)
    sanitize_for_json(x::AbstractDict) = OrderedCollections.OrderedDict(k => sanitize_for_json(v) for (k, v) in pairs(x))
    sanitize_for_json(x::AbstractVector) = sanitize_for_json.(x)
    sanitize_for_json(x::Tuple) = [sanitize_for_json(v) for v in x] # parsing Arrays needs less precompilation than Tuples
    sanitize_for_json(x) = x

    function json(x; kwargs...)
        JSON.json(sanitize_for_json(x); kwargs...)
    end
end

end
