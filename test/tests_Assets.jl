@safetestset "Assets functionality" begin

  @safetestset "Assets paths" begin
    using Genie, Genie.Assets

    @test include_asset(:css, "foo")  == "/assets/css/foo.css"
    @test include_asset(:js, "foo")   == "/assets/js/foo.js"

    @test css_asset("foo") == css("foo") == "/assets/css/foo.css"
    @test js_asset("foo") == js("foo") == "/assets/js/foo.js"
  end;

  @safetestset "Expose settings" begin
    using Genie, Genie.Assets

    @test js_settings() == "window.Genie = {};\nGenie.Settings = {\"websockets_exposed_port\":window.location.port,\"server_host\":\"127.0.0.1\",\"webchannels_autosubscribe\":true,\"env\":\"dev\",\"webchannels_eval_command\":\">eval:\",\"websockets_host\":\"127.0.0.1\",\"webthreads_js_file\":\"webthreads.js\",\"webchannels_unsubscribe_channel\":\"unsubscribe\",\"webthreads_default_route\":\"____\",\"webchannels_subscribe_channel\":\"subscribe\",\"server_port\":8000,\"webchannels_keepalive_frequency\":30000,\"websockets_exposed_host\":window.location.hostname,\"base_path\":\"\",\"websockets_protocol\":window.location.protocol.replace('http', 'ws'),\"webthreads_pull_route\":\"pull\",\"webchannels_default_route\":\"____\",\"webchannels_timeout\":1000,\"webthreads_push_route\":\"push\",\"websockets_port\":8000,\"websockets_base_path\":\"\"};\n"
  end

  @safetestset "Embedded assets" begin
    using Genie, Genie.Assets

    @test Assets.channels()[1:18] == "window.Genie = {};"
    @test channels_script()[1:27] == "<script>\nwindow.Genie = {};"

    @test channels_support() == "<script src=\"/genie.jl/master/assets/js/channels.js\"></script>"
    @test Genie.Router.routes()[1].path == "/genie.jl/master/assets/js/channels.js"
    @test Genie.Router.channels()[1].path == "/$(Genie.config.webchannels_default_route)/unsubscribe"
    @test Genie.Router.channels()[2].path == "/$(Genie.config.webchannels_default_route)/subscribe"

    @test favicon_support() == "<link rel=\"icon\" type=\"image/x-icon\" href=\"/favicon.ico\" />"
  end

end;
