salutation = "Hello"
name = "Adrian"

html_template = """
<h1>$salutation</h1>
<p>Welcome to our page, $name</p>
<button>Login</button>
<button>Sign up</button>
"""

type C
	lv1::Int64
	lv2::AbstractString

	C() = new(0, "")
	C(lv1, lv2) = new(lv1, lv2)
end

c = C()

d = Dict(
	:a => 5, :b => 10, :c => 15
)

function parse(html_string, vars)

end

# ====================

@show string(:photos, [], 2)

function dostuff(args...)
	args = tuple(string(args[1]), args[2], args[3])
	a, b, c = args
	@show a
end

dostuff(:photos)

# ========================

function matchpath(target, path)
  length(target) > length(path) && return "D"

	for i = 1:length(target)
    if startswith(target[i], ":")
      return "A"
    else
      target[i] == path[i] || return "B"
    end
  end

  return "C"
end

matchpath("/:id", Dict(:path => "foofer"))

target = [":id"]
params = Dict()
path = ["foofer"]
for i = 1:length(target)
	if startswith(target[i], ":")
		params[symbol(target[i][2:end])] = path[i]
	else
		target[i] == path[i] || return
	end
end

params

params == nothing && return "dudu"
merge!(params!(req), params)

length(target)
length(path)
typeof(target[1])
