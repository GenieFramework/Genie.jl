using Test, TestSetExtensions, SafeTestsets, Logging, Pkg
using HTTP, Genie, Pluto

include("html.jl")

function testnotebook(input)
    session = Pluto.ServerSession();
    notebook = Pluto.SessionActions.open(session, input; run_async=false)
    html_contents = body(notebook)

    # split input string by '--', '.' and '_' to array of strings
    # e.g. '18--a_b_c.jl' -> ['18', 'a', 'b', 'c', 'jl']
    # html_input string
    first_input = last(split(input, "/"))
    new_input = replace(last(split(split(first_input, ".")[1], "--")), r"_" => s"-")

    write(joinpath(@__DIR__, "../build/guides/","$(new_input).html"), html_contents)

    errored=false
    for c in notebook.cells
        if c.errored
            errored=true
            @error "Error in  $(c.cell_id): $(c.output.body[:msg])\n $(c.code)"
        end
        @assert !c.errored
        @test !c.errored
    end
    !errored
end


@testset "testing guides" begin
    @info @__DIR__
    notebooks= [
    "180--Working_With_Genie_Apps/180--Working_With_Genie_Apps.jl"
    ]
    for notebook in notebooks
        input=joinpath(@__DIR__,"PlutoNotebooks/",notebook)
        @show input
        @info "notebook: $(input)"
        @test testnotebook(input)
    end
end