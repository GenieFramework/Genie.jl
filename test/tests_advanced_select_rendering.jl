@safetestset "<select> test" begin

  using Genie
  using Genie.Renderer.Html
  import Genie.Util: fws

  @test html(filepath("formview.jl.html")).body |> String |> fws ==
        """<!DOCTYPE html><html><body><form method="POST" enctype="multipart/form-data" action="/new">
            <div class="form-group"><label for="exampleFormControlSelect1">Example select</label>
            <select class="form-control" id="exampleFormControlSelect1"><option>1</option><option>2</option>
            <option>3</option><option>4</option><option>5</option></select></div>
            <button class="btn btn-primary" type="submit">Submit</button></form></body></html>""" |> fws

end