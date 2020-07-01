@safetestset "JS rendering" begin
  @safetestset "JSON rendering" begin
    @safetestset "JSON view rendering with vars" begin
      using Genie, Genie.Renderer, Genie.Renderer.Json

      jsonview = raw"
      Dict(@vars(:root) => Dict(lang => greet for (lang,greet) in @vars(:greetings)))
      "

      viewfile = mktemp()
      write(viewfile[2], jsonview)
      close(viewfile[2])

      words = Dict(:en => "Hello", :es => "Hola", :pt => "Ola", :it => "Ciao")

      r = json(Genie.Renderer.Path(viewfile[1]), root = "greetings", greetings = words)

      @test String(r.body) == """{"greetings":{"en":"Hello","it":"Ciao","pt":"Ola","es":"Hola"}}"""

      Genie.Renderer.clear_task_storage()
    end;
  end;
end;