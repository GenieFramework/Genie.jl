include("cleanup.jl")

if isdir(joinpath("..","build"))
  @info "build dir exists"
else
  @info "build dir does not exist"
  mkdir(joinpath("..","build"))
end

if isdir(joinpath("..", "build", "guides"))
  @info "guides dir exist"
else
  @info "guides dir does not exist"
  mkdir(joinpath("..", "build", "guides"))
end

if isdir(joinpath("..", "build", "tutorials"))
  @info "tutorials dir exist"
else
  @info "tutorials dir does not exist"
  mkdir(joinpath("..", "build", "tutorials"))
end

t1 = `julia --project -e 'using Pkg; Pkg.instantiate(); include("runtest_tutorial.jl")'` |> run

if Base.process_exited(t1)
  Base.kill(t1)
end

t2 = `julia --project -e 'using Pkg; Pkg.instantiate(); include("runtest_tutorial_breaking.jl")'` |> run

if Base.process_exited(t2)
  Base.kill(t2)
end

t3 = `julia --project -e 'using Pkg; Pkg.instantiate(); include("runtest_guide.jl")'` |> run

if Base.process_exited(t3)
  Base.kill(t3)
end

t4 = `julia --project -e 'using Pkg; Pkg.instantiate(); include("runtest_guide_breaking.jl")'` |> run

if Base.process_exited(t4)
  Base.kill(t4)
end
