@safetestset "HTML attributes rendering" begin
  @safetestset "No attributes" begin
    using Genie.Renderer

    r = html("<div></div>")
    @test String(r.body) == "<html><head></head><body><div></div></body></html>"
  end;

  @safetestset "Regular attribute" begin
    using Genie.Renderer

    r = html("""<div class="foo"></div>""")
    @test String(r.body) == """<html><head></head><body><div class="foo"></div></body></html>"""
  end;

  @safetestset "Dashed attributes" begin
    using Genie.Renderer

    r = html("""<div data-arg="foo"></div>""")
    @test String(r.body) == """<html><head></head><body><div data-arg="foo"></div></body></html>"""
  end;

  @safetestset "Multiple dashed attributes" begin
    using Genie.Renderer

    r = html("""<div data-arg="foo bar" data-moo-hoo="123"></div>""")
    @test String(r.body) == """<html><head></head><body><div data-arg="foo bar" data-moo-hoo="123"></div></body></html>"""
  end;

  @safetestset "Single quotes" begin
    using Genie.Renderer

    r = html("<div class='foo'></div>")
    @test String(r.body) == """<html><head></head><body><div class="foo"></div></body></html>"""
  end;

  @safetestset "Vue args" begin
    using Genie
    using Genie.Renderer

    r = html("""<span v-bind:title="message">
    Hover your mouse over me for a few seconds
    to see my dynamically bound title!
  </span>""")
    @test String(r.body) == """<html><head></head><body><span v-bind:title="message">  Hover your mouse over me for a few seconds
    to see my dynamically bound title!
  </span></body></html>"""

    r = html("""<div id="app-3">
  <span v-if="seen">Now you see me</span>
</div>""")
    @test String(r.body) == """<html><head></head><body><div id="app-3"><span v-if="seen">Now you see me</span></div></body></html>"""

    r = html("""<div id="app-4">
    <ol>
      <li v-for="todo in todos">
        {{ todo.text }}
      </li>
    </ol>
  </div>""")
    @test String(r.body) == """<html><head></head><body><div id="app-4"><ol><li v-for="todo in todos">  {{ todo.text }}
    </li></ol></div></body></html>"""

    r = html("""<div id="app-5">
    <p>{{ message }}</p>
    <button v-on:click="reverseMessage">Reverse Message</button>
  </div>""")
    @test String(r.body) == """<html><head></head><body><div id="app-5"><p>{{ message }}</p><button v-on:click="reverseMessage">Reverse Message</button></div></body></html>"""

    r = html("""<div id="app-6">
    <p>{{ message }}</p>
    <input v-model="message">
  </div>""")
    @test String(r.body) == """<html><head></head><body><div id="app-6"><p>{{ message }}</p><input v-model="message"></div></body></html>"""

    Genie.Renderer.Html.register_element("todo-item")

    r = html("""<ol>
    <!-- Create an instance of the todo-item component -->
    <todo-item></todo-item>
  </ol>""")
    @test String(r.body) == """<html><head></head><body><ol><todo-item></todo-item></ol></body></html>"""

    r = html("""<div id="app-7">
    <ol>
      <!--
        Now we provide each todo-item with the todo object
        it's representing, so that its content can be dynamic.
        We also need to provide each component with a "key",
        which will be explained later.
      -->
      <todo-item
        v-for="item in groceryList"
        v-bind:todo="item"
        v-bind:key="item.id"
      ></todo-item>
    </ol>
  </div>""")
    @test String(r.body) == """<html><head></head><body><div id="app-7"><ol><todo-item v-for="item in groceryList" v-bind:todo="item" v-bind:key="item.id"></todo-item></ol></div></body></html>"""

    r = html("""<span v-on:click="upvote(submission.id)"></span>""")
    @test String(r.body) == """<html><head></head><body><span v-on:click="upvote(submission.id)"></span></body></html>"""

    r = html("""<span @click="upvote(submission.id)"></span>""")
    @test String(r.body) == """<html><head></head><body><span @click="upvote(submission.id)"></span></body></html>"""

    r = html("""<img v-bind:src="submission.submissionImage" />""")
    @test String(r.body) == """<html><head></head><body><img v-bind:src="submission.submissionImage"></body></html>"""

    r = html("""<img :src="submission.submissionImage" />""")
    @test String(r.body) == """<html><head></head><body><img :src="submission.submissionImage"></body></html>"""
  end;
end;