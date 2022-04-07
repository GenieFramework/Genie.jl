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

    write(joinpath(@__DIR__, "../build/tutorials/","$(new_input).html"), html_contents)

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


@testset "testing tutorials" begin
    notebooks= [
        "0--Index/0--index.jl",
        "1--Overview/1--Overview.jl",
        "2--Installing_Genie/2--Installing_Genie.jl",
        "3--Getting_Started/3--Getting_Started.jl",
        "4--Developing_Web_Services/4--Developing_Web_Services.jl",
        "41--Developing_MVC_Web_Apps/41--Developing_MVC_Web_Apps.jl",
        "5--Handling_Query_Params/5--Handling_Query_Params.jl",
        "6--Working_with_POST_Payloads/6--Working_with_POST_Payloads.jl",
        "8--Handling_File_Uploads/8--Handling_File_Uploads.jl",
        "9--Publishing_Your_Julia_Code_Online_With_Genie_Apps/9--Publishing_Your_Julia_Code_Online_With_Genie_Apps.jl",
        "10--Loading_Genie_Apps/10--Loading_Genie_Apps.jl",
        "11--Managing_External_Packages/11--Managing_External_Packages.jl",
        "13--Initializers/13--Initializers.jl",
        "14--The_Secrets_File/14--The_Secrets_File.jl",
        "15--The_Lib_Folder/15--The_Lib_Folder.jl",
        "16--Using_Genie_With_Docker/16--Using_Genie_With_Docker.jl",
        "17--Working_with_Web_Sockets/17--Working_with_Web_Sockets.jl",
        "80--Force_Compiling_Routes/80--Force_Compiling_Routes.jl",
        "90--Deploying_With_Heroku_Buildpacks/90--Deploying_With_Heroku_Buildpacks.jl",
        "92--Deploying_Genie_Server_Apps_with_Nginx/92--Deploying_Genie_Server_Apps_with_Nginx.jl"
    ]

    for notebook in notebooks
        input=joinpath(@__DIR__,"PlutoNotebooks/",notebook)
        @show input
        @info "notebook: $(input)"
        @test testnotebook(input)
    end
end