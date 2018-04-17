# Place here configuration options that will be set for all environments
if isdefined(:config)
  config.app_is_api = false
  config.cors_headers = Dict{String,String}(
      "Access-Control-Allow-Origin"  => "*",
      "Access-Control-Allow-Methods" => "GET, POST, PATCH, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers" => "Origin, Content-Type, X-Auth-Token",
    )
end
