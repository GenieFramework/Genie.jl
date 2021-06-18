using Pkg, Dates
Pkg.activate(".")

using Genie, Dates, HTTP
import Genie.Router: route, POST, params
import Base.convert

convert(::Type{Float64}, s::SubString{String}) = parse(Float64, s)
convert(::Type{Int}, s::SubString{String}) = parse(Int, s)
convert(::Type{Date}, s::SubString{String}) = Date(s)

route("/getparams/:s::String/:f::Float64/:i::Int/:d::Date") do
  @show "s = $(params(:s)) / f = $(params(:f)) / i = $(params(:i)) / $(params(:d))"
end
Genie.AppServer.startup(; open_browser = false)

HTTP.get("http://localhost:8000/getparams/foo/23.43/18/2019-02-15")

exit(0)
