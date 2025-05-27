import Genie, HTTP

"""
    method_override(req::HTTP.Request, res::HTTP.Response, 
        params::Dict{Symbol,Any})

Install a pre-match hook that rewrites POSTs carrying a hidden `_method` field 
into real PUT/PATCH/DELETE requests.

Place this code in, for example, `config/initializers/method_override.jl`:

# Example

```jldoctest
julia> using Genie, HTTP

julia> function method_override(req::HTTP.Request, res::HTTP.Response, 
    params::Dict{Symbol,Any})
    if req.method == "POST"
        post = get(params, Genie.Router.PARAMS_POST_KEY, Dict{Symbol,Any}())
        if haskey(post, :_method)
            m = uppercase(string(post[:_method]))
            if m in ("PUT","PATCH","DELETE")
                @info "Overriding method POST → $m"
                req.method = m
            end
        end
    end
    return req, res, params
end

julia> push!(Genie.Router.pre_match_hooks, method_override)

julia> route("/foo", named = :test_get_override) do
  "Hello from GET"
end

julia> route("/foo", method = POST, named = :test_post_override) do
  "Hello from POST"
end

julia> route("/foo",  method = PUT, named = :test_put_override) do
  "Hello from PUT"
end

julia> up(port=8000)

julia> HTTP.request("GET", "http://127.0.0.1:8000/foo")

julia> HTTP.request("POST", "http://127.0.0.1:8000/foo")

julia> HTTP.request("PUT", "http://127.0.0.1:8000/foo")

julia> Router.delete!(:test_get_override)

julia> Router.delete!(:test_post_override)

julia> Router.delete!(:test_put_override)
````
"""
function method_override(req::HTTP.Request, res::HTTP.Response, 
    params::Dict{Symbol,Any})
    if req.method == "POST"
        post = get(params, Genie.Router.PARAMS_POST_KEY, Dict{Symbol,Any}())
        if haskey(post, :_method)
            m = uppercase(string(post[:_method]))
            if m in ("PUT","PATCH","DELETE")
                @info "Overriding method POST → $m"
                req.method = m
            end
        end
    end
    return req, res, params
end

push!(Genie.Router.pre_match_hooks, method_override)
