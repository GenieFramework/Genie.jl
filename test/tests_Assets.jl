@safetestset "Assets functionality" begin

  @safetestset "Assets paths" begin
    using Genie, Genie.Assets

    @test include_asset(:css, "foo")  == "/css/foo.css"
    @test include_asset(:js, "foo")   == "/js/foo.js"

    @test css_asset("foo") == css("foo") == "/css/foo.css"
    @test js_asset("foo") == js("foo") == "/js/foo.js"
  end;

  @safetestset "Expose settings" begin
    using Genie, Genie.Assets

    @test js_settings() == "window.Genie = {};\nGenie.Settings = {\"webchannels_autosubscribe\":true,\"server_host\":\"127.0.0.1\",\"webchannels_subscribe_channel\":\"subscribe\",\"server_port\":8000,\"webchannels_default_route\":\"__\",\"webchannels_unsubscribe_channel\":\"unsubscribe\",\"websockets_port\":8001}\n"
  end

  @safetestset "Embedded assets" begin
    using Genie, Genie.Assets

    @test channels()[1:18] == "window.Genie = {};"
    @test channels_script()[1:27] == "<script>\nwindow.Genie = {};"

    @test channels_support() == "<script src=\"/__/channels.js?v=$(Genie.Configuration.GENIE_VERSION)\"></script>"
    @test Genie.Router.routes()[1].path == "/__/channels.js"
    @test Genie.Router.channels()[1].path == "/__/unsubscribe"
    @test Genie.Router.channels()[2].path == "/__/subscribe"

    @test favicon_support() == "<link rel=\"icon\" type=\"image/x-icon\" href=\"/favicon.ico\" />"
  end

end;