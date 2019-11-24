@safetestset "JS rendering" begin

  @safetestset "Plain JS rendering" begin
    using Genie
    using Genie.Renderer

    script = raw"var app = new Vue({el: '#app', data: { message: 'Hello Vue!' }})"

    r = js(script)

    @test String(r.body) == "var app = new Vue({el: '#app', data: { message: 'Hello Vue!' }})"
    @test r.headers[1]["Content-Type"] == "application/javascript; charset=utf-8"
  end;


  @safetestset "Vars JS rendering" begin
    using Genie
    using Genie.Renderer
    using Genie.Renderer.Flax.JSONRenderer.JSONParser

    data = JSON.json(("message" => "Hi Vue"))

    script = raw"var app = new Vue({el: '#app', data: $data})"

    r = js(script, data = data)

    @test String(r.body) == "var app = new Vue({el: '#app', data: {\"message\":\"Hi Vue\"}})"
    @test r.headers[1]["Content-Type"] == "application/javascript; charset=utf-8"
  end;

end;