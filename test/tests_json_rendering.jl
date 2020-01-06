using Genie.Renderer.Json

jsonview = raw"
Dict(@vars(:root) => Dict(lang => greet for (lang,greet) in @vars(:greetings)))
"

viewfile = mktemp()
write(viewfile[2], jsonview)
close(viewfile[2])

words = Dict(:en => "Hello", :es => "Hola", :pt => "Ola", :it => "Ciao")

@testset "JSON rendering" begin
  @testset "JSON view rendering with vars" begin
    r = json(Genie.Renderer.Path(viewfile[1]), root = "greetings", greetings = words)

    @test String(r.body) == """{"greetings":{"en":"Hello","it":"Ciao","pt":"Ola","es":"Hola"}}"""
  end;
end;