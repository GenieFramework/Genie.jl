module Vue

using Genie, Genie.Flax

function cdninclude()
  Flax.script(src="https://cdn.jsdelivr.net/npm/vue@2.5.17/dist/vue.js")
end


function injectapp(appid, methods::Dict{String,Union{Function,String,Number}} = Flax.SYNCABLE)
  cdninclude() *
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
        $(join(["$k: '$v'" for (k,v) in methods if startswith(k, Flax.SYNCPREFIX)], ", \n"))
      },
      computed: {
        $(join([""" $k: {
                      get: function () {
                        return this.$(replace(k, Flax.COMPUTEDPREFIX => Flax.SYNCPREFIX));
                      },
                      set: function (newVal) {
                        this.$(replace(k, Flax.COMPUTEDPREFIX => Flax.SYNCPREFIX)) = getFromServer(newVal, '$v');
                      }
                    }""" for (k,v) in methods if startswith(k, Flax.COMPUTEDPREFIX)], ", \n"))
      },
      methods: {
        $(join(["$k: function (event) { getFromServer(event.target.value, '$v'); }" for (k,v) in methods if startswith(k, Flax.METHODPREFIX)], ", \n"))
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
