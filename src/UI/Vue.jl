module Vue

using Genie, Genie.Flax, Genie.Router

function cdninclude()
  Flax.script(src="https://cdn.jsdelivr.net/npm/vue@2.5.17/dist/vue.js")
end


function setupchannels()
  Router.channel("/sync/invoke") do
    Flax.invoke_sync_callbacks(Router.@params(:payload))
  end
end


function injectapp(appid, syncables::Vector{SyncBinding} = Flax.SYNCABLE)
  cdninclude() * "\n\n" *
  Flax.script("""
    var getFromServer = function (val = '', invoke = '') {
      i = prompt('Invoking on server ' + invoke, val);
      if ( i.startsWith('js:') ) {
        eval(i.substr(3));
      } else return i;
    };

    var gvm = new Vue({
      el: '$appid',
      data: {
        $(join(["$(s.key): '$(s.data)'" for s in syncables if s.typ == :data], ", \n"))
      },
      computed: {
        $(join([""" $(s.key): {
                      get: function () {
                        return this.$(replace(s.key, Flax.COMPUTEDPREFIX => Flax.DATAPREFIX));
                      },
                      set: function (newVal) {
                        this.$(replace(s.key, Flax.COMPUTEDPREFIX => Flax.DATAPREFIX)) = $(s.sync ? "getFromServer(newVal, '$(s.data)')" : "newVal");
                      }
                    }""" for s in syncables if s.typ == :computed], ", \n"))
      },
      methods: {
        $(join(["$(s.key): function (event) { $(s.sync ? "getFromServer(event.target.value, '$(s.data)')" : Flax.extract(s.data)); }" for s in syncables if s.typ == :method], ", \n"))
      }
    });
  """)
end


function injectwebchannels()
  Flax.script("""
    $(join(readlines(joinpath(@__DIR__, "..", "..", "files", "new_app", "app", "assets", "js", "channels.js") |> normpath), "\n"))
    WebChannels.load_channels();
    WebChannels.messageHandlers.push(function(event){
      console.log(event.data);
    });
  """)
end


end
