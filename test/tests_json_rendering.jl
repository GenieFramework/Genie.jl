@safetestset "JS rendering" begin
  @safetestset "JSON rendering" begin
    @safetestset "JSON view rendering with vars" begin
      using Genie, Genie.Renderer, Genie.Renderer.Json

      jsonview = raw"
      Dict(vars(:root) => Dict(lang => greet for (lang,greet) in vars(:greetings)))
      "

      viewfile = mktemp()
      write(viewfile[2], jsonview)
      close(viewfile[2])

      words = Dict(:en => "Hello", :es => "Hola", :pt => "Ola", :it => "Ciao")

      r = json(Genie.Renderer.Path(viewfile[1]), root = "greetings", greetings = words)

      json_str = String(r.body)
      @test json_str == """{"greetings":{"en":"Hello","it":"Ciao","pt":"Ola","es":"Hola"}}""" ||
            json_str == """{"greetings":{"en":"Hello","es":"Hola","it":"Ciao","pt":"Ola"}}"""

      Genie.Renderer.clear_task_storage()
    end;

    @safetestset "JSON struct rendering" begin
      struct Person
        name::String
        age::Int
      end

      p = Person("John Doe", 42)

      using Genie.Renderers.Json

      @test String(json(p).body) == """{"name":"John Doe","age":42}"""
    end
  end;
end;