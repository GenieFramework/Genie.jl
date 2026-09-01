# @testitem "HTML attributes rendering" setup=[GenieTestSetup] begin
  @testitem "No attributes" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html

    r = html("<div></div>")
    @test String(r.body) == "<div></div>"
  end;

  @testitem "No attributes force parse" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    r = html("<div></div>", forceparse = true)
    @test String(r.body) |> fws == "<!DOCTYPE html><html><body><div></div></body></html>" |> fws
  end;


  @testitem "Regular attribute" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    r = html("""<div class="foo"></div>""")
    @test String(r.body) |> fws == """<div class="foo"></div>""" |> fws
  end;

  @testitem "Regular attribute force parse" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    r = html("""<div class="foo"></div>""", forceparse = true)
    @test String(r.body) |> fws == """<!DOCTYPE html><html><body><div class="foo"></div></body></html>""" |> fws
  end;


  @testitem "Dashed attributes" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    r = html("""<div data-arg="foo"></div>""")
    @test String(r.body) |> fws == """<div data-arg="foo"></div>""" |> fws
  end;

  @testitem "Dashed attributes force parse" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    r = html("""<div data-arg="foo"></div>""", forceparse = true)
    @test String(r.body) |> fws == """<!DOCTYPE html><html><body><div data-arg="foo"></div></body></html>""" |> fws
  end;


  @testitem "Multiple dashed attributes" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    r = html("""<div data-arg="foo bar" data-moo-hoo="123"></div>""")
    @test String(r.body) |> fws == """<div data-arg="foo bar" data-moo-hoo="123"></div>""" |> fws
  end;

  @testitem "Multiple dashed attributes force parse" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    r = html("""<div data-arg="foo bar" data-moo-hoo="123"></div>""", forceparse = true)
    @test String(r.body) |> fws == """<!DOCTYPE html><html><body><div data-arg="foo bar" data-moo-hoo="123"></div></body></html>""" |> fws
  end;

  @testitem "Attribute value with `=` character" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    r = html("""<div onclick="event = true"></div>""")
    @test String(r.body) |> fws == """<div onclick="event = true"></div>""" |> fws
    r = html("""<div onclick="event = true"></div>""", forceparse=true)
    @test String(r.body) |> fws == """<!DOCTYPE html><html><body><div onclick="event = true"></div></body></html>""" |> fws

    r = html("<div v-on:click='event = true'></div>")
    @test String(r.body) |> fws == "<div v-on:click='event = true'></div>" |> fws
    r = html("<div v-on:click='event = true'></div>", forceparse=true)
    @test String(r.body) |> fws == """<!DOCTYPE html><html><body><div v-on:click="event = true"></div></body></html>""" |> fws
  end;

  @testitem "Single quotes" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    r = html("<div class='foo'></div>")
    @test String(r.body) |> fws == """<div class='foo'></div>""" |> fws
  end;

  @testitem "Single quotes force parse" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    r = html("<div class='foo'></div>", forceparse = true)
    @test String(r.body) |> fws == """<!DOCTYPE html><html><body><div class="foo"></div></body></html>""" |> fws
  end;


  @testitem "Vue args force parse" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    r = html("""<span v-bind:title="message">
    Hover your mouse over me for a few seconds
    to see my dynamically bound title!
  </span>""", forceparse = true)

    @test String(r.body) |> fws == """<!DOCTYPE html><html><body><span v-bind:title="message">  Hover your mouse over me for a few seconds
                            to see my dynamically bound title!
                            </span></body></html>""" |> fws

    r = html("""<div id="app-3">
                  <span v-if="seen">Now you see me</span>
                </div>""", forceparse = true)

    @test String(r.body) |> fws ==
          """<!DOCTYPE html><html><body><div id="app-3"><span v-if="seen">Now you see me</span></div></body></html>""" |> fws

    r = html("""<div id="app-4">
                  <ol>
                    <li v-for="todo in todos">
                      {{ todo.text }}
                    </li>
                  </ol>
                </div>""", forceparse = true)

    @test String(r.body) |> fws ==
          """<!DOCTYPE html><html><body><div id="app-4"><ol><li v-for="todo in todos">  {{ todo.text }}
              </li></ol></div></body></html>""" |> fws

    r = html("""<div id="app-5">
                  <p>{{ message }}</p>
                  <button v-on:click="reverseMessage">Reverse Message</button>
                </div>""", forceparse = true)

    @test String(r.body) |> fws ==
          """<!DOCTYPE html><html><body><div id="app-5"><p>{{ message }}</p>
              <button v-on:click="reverseMessage">Reverse Message</button></div></body></html>""" |> fws

    r = html("""<div id="app-6">
                  <p>{{ message }}</p>
                  <input v-model="message">
                </div>""", forceparse = true)

    @test String(r.body) |> fws ==
          """<!DOCTYPE html><html><body><div id="app-6"><p>{{ message }}</p>
          <input v-model="message"$(Genie.config.html_parser_close_tag)></div></body></html>""" |> fws

    Genie.Renderer.Html.register_element("todo-item")

    r = html("""<ol>
                  <!-- Create an instance of the todo-item component -->
                  <todo-item></todo-item>
                </ol>""", forceparse = true)

    @test String(r.body) |> fws ==
          """<!DOCTYPE html><html><body><ol><!-- Create an instance of the todo-item component --><todo-item></todo-item>
          </ol></body></html>""" |> fws

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
                </div>""", forceparse = true)

    @test String(r.body) |> fws ==
    """<!DOCTYPE html><html><body><div id="app-7"><ol><!--
    Now we provide each todo-item with the todo object
    it's representing, so that its content can be dynamic.
    We also need to provide each component with a "key",
    which will be explained later.
    --><todo-item v-for="item in groceryList" v-bind:todo="item" v-bind:key="item.id">
    </todo-item></ol></div></body></html>""" |> fws

    r = html("""<span v-on:click="upvote(submission.id)"></span>""", forceparse = true)
    @test String(r.body) |> fws ==
          """<!DOCTYPE html><html><body><span v-on:click="upvote(submission.id)"></span></body></html>""" |> fws

    r = html("""<span v-on:click="upvote(submission.id)"></span>""", forceparse = true)
    @test String(r.body) |> fws ==
          """<!DOCTYPE html><html><body><span v-on:click="upvote(submission.id)"></span></body></html>""" |> fws

    r = html("""<img v-bind:src="submission.submissionImage" />""", forceparse = true)
    @test String(r.body) |> fws ==
          """<!DOCTYPE html><html><body><img v-bind:src="submission.submissionImage"$(Genie.config.html_parser_close_tag)>
          </body></html>""" |> fws

    r = html("""<img :src="submission.submissionImage" />""", forceparse = true)
    @test String(r.body) |> fws ==
          """<!DOCTYPE html><html><body><img :src="submission.submissionImage"$(Genie.config.html_parser_close_tag)>
          </body></html>""" |> fws
  end;

  @testitem "Embedded Julia" setup=[GenieTestSetup] begin
    using Genie.Renderer.Html
    import Genie.Util: fws

    id = 10
    r = html(raw"""<span id="$id"></span>""", id = 10)
    @test String(r.body) |> fws == """<!DOCTYPE html><html><body><span id="10"></span></body></html>""" |> fws

    r = html(raw"""<span id="$(string(:moo))"></span>""", forceparse = true)
    @test String(r.body) |> fws == """<!DOCTYPE html><html><body><span id="moo"></span></body></html>""" |> fws

    r = html("""<span $(string(:disabled))></span>""", forceparse = true)
    @test String(r.body) |> fws == """<!DOCTYPE html><html><body><span disabled="disabled"></span></body></html>""" |> fws

    r = html("""<span $("foo=$(string(:disabled))")></span>""", forceparse = true)
    @test String(r.body) |> fws == """<!DOCTYPE html><html><body><span foo="disabled"></span></body></html>""" |> fws
  end;
# end;
